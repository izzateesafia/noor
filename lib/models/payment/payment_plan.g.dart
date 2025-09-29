// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentPlan _$PaymentPlanFromJson(Map<String, dynamic> json) => PaymentPlan(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  currency: json['currency'] as String,
  interval: json['interval'] as String,
  features: (json['features'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isPopular: json['isPopular'] as bool? ?? false,
);

Map<String, dynamic> _$PaymentPlanToJson(PaymentPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'currency': instance.currency,
      'interval': instance.interval,
      'features': instance.features,
      'isPopular': instance.isPopular,
    };
