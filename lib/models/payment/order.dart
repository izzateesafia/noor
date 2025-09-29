import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String? id;
  final double? amount;
  final String? currency;
  final String? description;
  final String? status;
  final String? userId;
  final String? planId;
  final String? secretKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    this.id,
    this.amount,
    this.currency,
    this.description,
    this.status,
    this.userId,
    this.planId,
    this.secretKey,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

