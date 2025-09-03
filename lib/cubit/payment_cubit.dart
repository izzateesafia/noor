import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/payment.dart';
import '../repository/payment_repository.dart';
import 'payment_states.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;
  
  PaymentCubit(this.repository) : super(const PaymentState());

  // Fetch user payments
  Future<void> getUserPayments(String userId) async {
    emit(state.copyWith(status: PaymentCubitStatus.loading));
    
    try {
      final payments = await repository.getUserPayments(userId);
      emit(state.copyWith(
        status: PaymentCubitStatus.loaded,
        payments: payments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Fetch user subscription
  Future<void> getUserSubscription(String userId) async {
    try {
      final subscription = await repository.getUserSubscription(userId);
      emit(state.copyWith(currentSubscription: subscription));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Fetch available payment plans
  Future<void> getAvailablePlans() async {
    emit(state.copyWith(status: PaymentCubitStatus.loading));
    
    try {
      final plans = await repository.getAvailablePlans();
      emit(state.copyWith(
        status: PaymentCubitStatus.loaded,
        availablePlans: plans,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Process payment
  Future<void> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required PaymentType type,
    required PaymentMethod method,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    emit(state.copyWith(
      isProcessingPayment: true,
      status: PaymentCubitStatus.loading,
    ));
    
    try {
      // Create payment intent with Stripe
      final paymentIntent = await repository.createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description ?? 'Payment for ${type.toString().split('.').last}',
        metadata: metadata,
      );

      // Create payment record
      final payment = Payment(
        id: '', // Will be set by Firestore
        userId: userId,
        amount: amount,
        currency: currency,
        type: type,
        status: PaymentStatus.pending,
        method: method,
        description: description,
        stripePaymentIntentId: paymentIntent['id'],
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Save payment to Firestore
      await repository.savePayment(payment);
      
      emit(state.copyWith(
        status: PaymentCubitStatus.loaded,
        isProcessingPayment: false,
        lastPayment: payment,
        processingPayment: payment,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        isProcessingPayment: false,
        error: e.toString(),
      ));
    }
  }

  // Confirm payment
  Future<void> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    emit(state.copyWith(
      isProcessingPayment: true,
      status: PaymentCubitStatus.loading,
    ));
    
    try {
      final result = await repository.confirmPaymentIntent(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      // Update payment status based on result
      final status = result['status'] == 'succeeded' 
          ? PaymentStatus.completed 
          : PaymentStatus.failed;

      if (state.processingPayment != null) {
        final updatedPayment = state.processingPayment!.copyWith(
          status: status,
          completedAt: status == PaymentStatus.completed ? DateTime.now() : null,
        );

        // Update payment in Firestore
        await repository.updatePaymentStatus(
          updatedPayment.id,
          status,
        );

        emit(state.copyWith(
          status: PaymentCubitStatus.loaded,
          isProcessingPayment: false,
          lastPayment: updatedPayment,
          processingPayment: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        isProcessingPayment: false,
        error: e.toString(),
      ));
    }
  }

  // Create subscription
  Future<void> createSubscription({
    required String userId,
    required PaymentPlan plan,
  }) async {
    emit(state.copyWith(
      isProcessingPayment: true,
      status: PaymentCubitStatus.loading,
    ));
    
    try {
      final subscription = Subscription(
        id: '',
        userId: userId,
        planId: plan.id,
        planName: plan.name,
        price: plan.price,
        currency: plan.currency,
        interval: plan.interval,
        startDate: DateTime.now(),
        isActive: true,
      );

      await repository.createSubscription(subscription);
      
      emit(state.copyWith(
        status: PaymentCubitStatus.loaded,
        isProcessingPayment: false,
        currentSubscription: subscription,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        isProcessingPayment: false,
        error: e.toString(),
      ));
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    emit(state.copyWith(status: PaymentCubitStatus.loading));
    
    try {
      await repository.cancelSubscription(subscriptionId);
      
      // Update local state
      if (state.currentSubscription != null) {
        final updatedSubscription = state.currentSubscription!.copyWith(
          isActive: false,
          endDate: DateTime.now(),
          status: PaymentStatus.cancelled,
        );
        
        emit(state.copyWith(
          status: PaymentCubitStatus.loaded,
          currentSubscription: updatedSubscription,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Process refund
  Future<void> processRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  }) async {
    emit(state.copyWith(status: PaymentCubitStatus.loading));
    
    try {
      await repository.processRefund(
        paymentIntentId: paymentIntentId,
        amount: amount,
        reason: reason,
      );
      
      // Refresh payments to show updated status
      if (state.payments.isNotEmpty) {
        final userId = state.payments.first.userId;
        await getUserPayments(userId);
      }
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics(String userId) async {
    try {
      return await repository.getPaymentAnalytics(userId);
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // Initialize default payment plans (for admin use)
  Future<void> initializeDefaultPlans() async {
    emit(state.copyWith(status: PaymentCubitStatus.loading));
    
    try {
      await repository.initializeDefaultPlans();
      await getAvailablePlans(); // Refresh plans
    } catch (e) {
      emit(state.copyWith(
        status: PaymentCubitStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Clear error
  void clearError() {
    emit(state.copyWith(
      status: PaymentCubitStatus.initial,
      error: null,
    ));
  }

  // Reset state
  void reset() {
    emit(const PaymentState());
  }

  // Update payment status locally (for real-time updates)
  void updatePaymentStatus(String paymentId, PaymentStatus status) {
    final updatedPayments = state.payments.map((payment) {
      if (payment.id == paymentId) {
        return payment.copyWith(
          status: status,
          completedAt: status == PaymentStatus.completed ? DateTime.now() : null,
        );
      }
      return payment;
    }).toList();

    emit(state.copyWith(payments: updatedPayments));
  }

  // Add new payment to list
  void addPayment(Payment payment) {
    final updatedPayments = [payment, ...state.payments];
    emit(state.copyWith(
      payments: updatedPayments,
      lastPayment: payment,
    ));
  }

  // Remove payment from list
  void removePayment(String paymentId) {
    final updatedPayments = state.payments.where((p) => p.id != paymentId).toList();
    emit(state.copyWith(payments: updatedPayments));
  }
} 