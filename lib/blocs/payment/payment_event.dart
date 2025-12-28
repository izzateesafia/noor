part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class InitPayment extends PaymentEvent {
  final CardDetails? cardDetails;
  final OrderRequest orderRequest;
  final String? totalAmount;
  final String planId;
  final String? savedPaymentMethodId; // Optional: use saved payment method

  const InitPayment({
    this.cardDetails,
    this.totalAmount,
    required this.planId,
    required this.orderRequest,
    this.savedPaymentMethodId,
  });

  @override
  List<Object?> get props => [cardDetails, orderRequest, totalAmount, planId, savedPaymentMethodId];
}

class LoadPayment extends PaymentEvent {
  const LoadPayment();
}

class LoadPaymentPlans extends PaymentEvent {
  const LoadPaymentPlans();
}

class LoadUserOrders extends PaymentEvent {
  final String userId;

  const LoadUserOrders({required this.userId});

  @override
  List<Object> get props => [userId];
}

class ConfirmPayment extends PaymentEvent {
  final String paymentIntentId;
  final String paymentMethodId;

  const ConfirmPayment({
    required this.paymentIntentId,
    required this.paymentMethodId,
  });

  @override
  List<Object> get props => [paymentIntentId, paymentMethodId];
}

class UpdateOrderStatus extends PaymentEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object> get props => [orderId, status];
}

class ClearPaymentError extends PaymentEvent {
  const ClearPaymentError();
}

class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}
