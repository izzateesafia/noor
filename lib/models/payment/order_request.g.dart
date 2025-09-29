// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequest _$OrderRequestFromJson(Map<String, dynamic> json) => OrderRequest(
  userId: json['user_id'] as String?,
  planId: json['plan_id'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
  description: json['description'] as String?,
  email: json['email'] as String?,
  fullName: json['full_name'] as String?,
  phoneNumber: json['phone_number'] as String?,
  paymentMethod: json['payment_method'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderRequestToJson(OrderRequest instance) =>
    <String, dynamic>{
      'user_id': ?instance.userId,
      'plan_id': ?instance.planId,
      'amount': ?instance.amount,
      'currency': ?instance.currency,
      'description': ?instance.description,
      'email': ?instance.email,
      'full_name': ?instance.fullName,
      'phone_number': ?instance.phoneNumber,
      'payment_method': ?instance.paymentMethod,
      'metadata': ?instance.metadata,
    };
