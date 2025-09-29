import 'package:json_annotation/json_annotation.dart';

part 'payment_plan.g.dart';

@JsonSerializable()
class PaymentPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // e.g., 'monthly', 'yearly'
  final List<String> features;
  final bool isPopular;

  const PaymentPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    this.isPopular = false,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) => _$PaymentPlanFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentPlanToJson(this);
}

