enum PaymentStatus { initial, pending, processing, completed, failed, cancelled }
enum PaymentType { subscription, oneTime, donation, classEnrollment }
enum PaymentMethod { card, applePay, googlePay, bankTransfer }

class Payment {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? description;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.method,
    this.description,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${json['type']}',
        orElse: () => PaymentType.oneTime,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['method']}',
        orElse: () => PaymentMethod.card,
      ),
      description: json['description'] as String?,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'method': method.toString().split('.').last,
      'description': description,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentType? type,
    PaymentStatus? status,
    PaymentMethod? method,
    String? description,
    String? stripePaymentIntentId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      method: method ?? this.method,
      description: description ?? this.description,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final double price;
  final String currency;
  final String interval; // monthly, yearly, lifetime
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? stripeSubscriptionId;
  final PaymentStatus status;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.price,
    required this.currency,
    required this.interval,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.stripeSubscriptionId,
    this.status = PaymentStatus.completed,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] as bool,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.completed,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'price': price,
      'currency': currency,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'stripeSubscriptionId': stripeSubscriptionId,
      'status': status.toString().split('.').last,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? planId,
    String? planName,
    double? price,
    String? currency,
    String? interval,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? stripeSubscriptionId,
    PaymentStatus? status,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      status: status ?? this.status,
    );
  }
}

class PaymentPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval;
  final List<String> features;
  final bool isPopular;
  final String? stripePriceId;
  final int? trialDays;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    this.isPopular = false,
    this.stripePriceId,
    this.trialDays,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      features: (json['features'] as List<dynamic>).cast<String>(),
      isPopular: json['isPopular'] as bool? ?? false,
      stripePriceId: json['stripePriceId'] as String?,
      trialDays: json['trialDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'isPopular': isPopular,
      'stripePriceId': stripePriceId,
      'trialDays': trialDays,
    };
  }
} 