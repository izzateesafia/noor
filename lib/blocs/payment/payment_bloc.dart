import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../models/payment/order_request.dart';
import '../../models/payment/order.dart' as payment_models;
import '../../models/payment/payment_plan.dart';
import '../../repository/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository = PaymentRepository();

  PaymentBloc() : super(PaymentInitial()) {
    on<InitPayment>(_initPayment);
    on<LoadPayment>(_loadPayment);
    on<LoadPaymentPlans>(_loadPaymentPlans);
    on<LoadUserOrders>(_loadUserOrders);
    on<ConfirmPayment>(_confirmPayment);
    on<UpdateOrderStatus>(_updateOrderStatus);
    on<ClearPaymentError>(_clearPaymentError);
    on<ResetPaymentState>(_resetPaymentState);
  }

  Future<void> _loadPayment(
    LoadPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoaded());
  }

  Future<void> _initPayment(
    InitPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final orderRequest = event.orderRequest;

    try {
      // Create order with payment intent
      payment_models.Order order = await repository.createOrder(
        userId: orderRequest.userId!,
        planId: event.planId,
        amount: orderRequest.amount!,
        currency: orderRequest.currency ?? 'MYR',
        description: orderRequest.description,
      );

      // Ensure we have all components
      if (order.amount == null || order.amount! <= 0) {
        throw Exception("Invalid order amount");
      }

      // Use the exact same calculation as order
      final totalAmount = event.totalAmount!;
      debugPrint("Total Amount for Payment: \$$totalAmount");

      if (event.cardDetails != null) {
        await Stripe.instance.dangerouslyUpdateCardDetails(event.cardDetails!);
      }

      try {
        final billingDetails = BillingDetails(
          email: orderRequest.email,
          phone: orderRequest.phoneNumber,
          name: orderRequest.fullName,
        );

        if (event.cardDetails != null) {
          // Card payment
          print('pay via card');
          final paymentMethodParams = PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: billingDetails,
            ),
          );

          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: order.secretKey!,
            data: paymentMethodParams,
          );
        } else {
          // Apple Pay
          await Stripe.instance.confirmPlatformPayPaymentIntent(
            clientSecret: order.secretKey!,
            confirmParams: PlatformPayConfirmParams.applePay(
              applePay: ApplePayParams(
                merchantCountryCode: 'MY',
                currencyCode: 'MYR',
                cartItems: [
                  ApplePayCartSummaryItem.immediate(
                    label: 'Daily Quran Premium',
                    amount: totalAmount,
                  )
                ],
              ),
            ),
          );
        }

        // Update order status to completed
        await repository.updateOrderStatus(order.id!, 'completed');
        
        // Update user premium status
        await _updateUserPremiumStatus(order.userId!, event.planId);

        emit(PaymentSuccess(order: order));
      } catch (e) {
        print(e);
        print("=====1");

        if (e is StripeException) {
          Map<String, dynamic> error = e.toJson();
          debugPrint(order.toJson().toString());
          print("stripe exception: ${error.toString()}");

          final errorMsg = error["error"];
          if (errorMsg is LocalizedErrorMessage) {
            emit(PaymentError(
              message: "Payment cancelled. Your order wasn't placed — feel free to try again anytime.",
            ));
          }
        } else {
          emit(PaymentError(
            message: "Something went wrong with the payment. Please try again.",
          ));
        }
      }
    } catch (e) {
      emit(PaymentError(
        message: "Something went wrong with the payment. Please try again.",
      ));
    }
  }

  Future<void> _loadPaymentPlans(
    LoadPaymentPlans event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final plans = await repository.getAvailablePlans();
      emit(PaymentPlansLoaded(plans: plans));
    } catch (e) {
      emit(PaymentError(message: "Failed to load payment plans: $e"));
    }
  }

  Future<void> _loadUserOrders(
    LoadUserOrders event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final orders = await repository.getUserOrders(event.userId);
      emit(UserOrdersLoaded(orders: orders));
    } catch (e) {
      emit(PaymentError(message: "Failed to load user orders: $e"));
    }
  }

  Future<void> _confirmPayment(
    ConfirmPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentProcessing(message: "Confirming payment..."));
    
    try {
      final result = await repository.confirmPayment(
        paymentIntentId: event.paymentIntentId,
        paymentMethodId: event.paymentMethodId,
      );
      
      if (result['status'] == 'succeeded') {
        emit(const PaymentLoaded());
      } else {
        emit(PaymentError(message: "Payment confirmation failed"));
      }
    } catch (e) {
      emit(PaymentError(message: "Failed to confirm payment: $e"));
    }
  }

  Future<void> _updateOrderStatus(
    UpdateOrderStatus event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      await repository.updateOrderStatus(event.orderId, event.status);
      emit(const PaymentLoaded());
    } catch (e) {
      emit(PaymentError(message: "Failed to update order status: $e"));
    }
  }

  Future<void> _clearPaymentError(
    ClearPaymentError event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentInitial());
  }

  Future<void> _resetPaymentState(
    ResetPaymentState event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentInitial());
  }

  // Helper method to update user premium status or class enrollment
  Future<void> _updateUserPremiumStatus(String userId, String planId) async {
    try {
      if (planId.startsWith('class_')) {
        // Handle class enrollment - no premium status change needed
        // You can add class enrollment logic here if needed
        print('PaymentBloc: Class enrollment successful for user: $userId, class: $planId');
        return;
      }
      
      // Handle premium subscription
      // Calculate expiry date based on plan
      DateTime expiryDate;
      if (planId == 'monthly') {
        expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (planId == 'yearly') {
        expiryDate = DateTime.now().add(const Duration(days: 365));
      } else if (planId == 'lifetime') {
        expiryDate = DateTime.now().add(const Duration(days: 36500)); // 100 years
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 30)); // Default
      }

      await repository.updateUserPremiumStatus(
        userId: userId,
        isPremium: true,
        premiumExpiryDate: expiryDate,
        planId: planId,
      );
      
      print('PaymentBloc: Premium status updated successfully for user: $userId');
    } catch (e) {
      print('Error updating user premium status: $e');
    }
  }
}
