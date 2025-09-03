import 'package:equatable/equatable.dart';
import '../models/payment.dart';

enum PaymentCubitStatus { initial, loading, loaded, error }

class PaymentState extends Equatable {
  final PaymentCubitStatus status;
  final List<Payment> payments;
  final Payment? lastPayment;
  final Subscription? currentSubscription;
  final List<PaymentPlan> availablePlans;
  final String? error;
  final bool isProcessingPayment;
  final Payment? processingPayment;

  const PaymentState({
    this.status = PaymentCubitStatus.initial,
    this.payments = const [],
    this.lastPayment,
    this.currentSubscription,
    this.availablePlans = const [],
    this.error,
    this.isProcessingPayment = false,
    this.processingPayment,
  });

  PaymentState copyWith({
    PaymentCubitStatus? status,
    List<Payment>? payments,
    Payment? lastPayment,
    Subscription? currentSubscription,
    List<PaymentPlan>? availablePlans,
    String? error,
    bool? isProcessingPayment,
    Payment? processingPayment,
  }) {
    return PaymentState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      lastPayment: lastPayment ?? this.lastPayment,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      availablePlans: availablePlans ?? this.availablePlans,
      error: error,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      processingPayment: processingPayment ?? this.processingPayment,
    );
  }

  @override
  List<Object?> get props => [
        status,
        payments,
        lastPayment,
        currentSubscription,
        availablePlans,
        error,
        isProcessingPayment,
        processingPayment,
      ];

  // Helper methods for common state checks
  bool get isLoading => status == PaymentCubitStatus.loading;
  bool get hasError => status == PaymentCubitStatus.error;
  bool get isLoaded => status == PaymentCubitStatus.loaded;
  bool get hasPayments => payments.isNotEmpty;
  bool get hasSubscription => currentSubscription != null && currentSubscription!.isActive;
  bool get hasPlans => availablePlans.isNotEmpty;

  // Get successful payments only
  List<Payment> get successfulPayments => 
      payments.where((p) => p.status == PaymentStatus.completed).toList();

  // Get pending payments only
  List<Payment> get pendingPayments => 
      payments.where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.processing).toList();

  // Get failed payments only
  List<Payment> get failedPayments => 
      payments.where((p) => p.status == PaymentStatus.failed).toList();

  // Get total amount spent
  double get totalSpent => successfulPayments.fold(0.0, (sum, payment) => sum + payment.amount);

  // Get most recent payment
  Payment? get mostRecentPayment => payments.isNotEmpty ? payments.first : null;
} 