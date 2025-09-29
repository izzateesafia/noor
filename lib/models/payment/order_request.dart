import 'package:json_annotation/json_annotation.dart';

part 'order_request.g.dart';

@JsonSerializable()
class OrderRequest {
  @JsonKey(name: "user_id", includeIfNull: false)
  final String? userId;

  @JsonKey(name: "plan_id", includeIfNull: false)
  final String? planId;

  @JsonKey(name: "amount", includeIfNull: false)
  final double? amount;

  @JsonKey(name: "currency", includeIfNull: false)
  final String? currency;

  @JsonKey(name: "description", includeIfNull: false)
  final String? description;

  @JsonKey(name: "email", includeIfNull: false)
  final String? email;

  @JsonKey(name: "full_name", includeIfNull: false)
  final String? fullName;

  @JsonKey(name: "phone_number", includeIfNull: false)
  final String? phoneNumber;

  @JsonKey(name: "payment_method", includeIfNull: false)
  final String? paymentMethod;

  @JsonKey(name: "metadata", includeIfNull: false)
  final Map<String, dynamic>? metadata;

  OrderRequest({
    this.userId,
    this.planId,
    this.amount,
    this.currency,
    this.description,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.paymentMethod,
    this.metadata,
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestToJson(this);
}

