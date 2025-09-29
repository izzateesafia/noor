part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  const PaymentLoaded();
  
  @override
  List<Object> get props => [];
}

class PaymentError extends PaymentState {
  final String? message;

  const PaymentError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class PaymentPlansLoaded extends PaymentState {
  final List<PaymentPlan> plans;

  const PaymentPlansLoaded({required this.plans});
  
  @override
  List<Object> get props => [plans];
}

class UserOrdersLoaded extends PaymentState {
  final List<payment_models.Order> orders;

  const UserOrdersLoaded({required this.orders});
  
  @override
  List<Object> get props => [orders];
}

class PaymentProcessing extends PaymentState {
  final String message;

  const PaymentProcessing({required this.message});
  
  @override
  List<Object> get props => [message];
}

class PaymentSuccess extends PaymentState {
  final payment_models.Order order;

  const PaymentSuccess({required this.order});
  
  @override
  List<Object> get props => [order];
}

class PaymentCancelled extends PaymentState {
  const PaymentCancelled();
  
  @override
  List<Object> get props => [];
}
