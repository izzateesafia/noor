import 'package:dio/dio.dart';

class PaymentService {
  static PaymentService? _instance;
  late Dio _dio;

  factory PaymentService() => _instance ??= PaymentService._();

  PaymentService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.stripe.com/v1', // Replace with your backend API
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer ${const String.fromEnvironment('STRIPE_SECRET_KEY', defaultValue: 'sk_test_your_stripe_secret_key_here')}',
        },
      ),
    );
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final formData = {
        'amount': (amount * 100).round().toString(), // Convert to cents
        'currency': currency.toLowerCase(),
        'automatic_payment_methods[enabled]': 'true',
        'metadata[user_id]': userId,
        if (description != null) 'description': description,
      };

      // Add metadata if provided
      if (metadata != null) {
        for (final entry in metadata.entries) {
          formData['metadata[${entry.key}]'] = entry.value.toString();
        }
      }

      final response = await _dio.post('/payment_intents', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Confirm payment intent
  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _dio.post(
        '/payment_intents/$paymentIntentId/confirm',
        data: {
          'payment_method': paymentMethodId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  // Create payment method
  Future<Map<String, dynamic>> createPaymentMethod({
    required Map<String, dynamic> cardData,
    required Map<String, dynamic> billingDetails,
  }) async {
    try {
      final formData = {
        'type': 'card',
        'card[number]': cardData['number'],
        'card[exp_month]': cardData['exp_month'].toString(),
        'card[exp_year]': cardData['exp_year'].toString(),
        'card[cvc]': cardData['cvc'],
        'billing_details[email]': billingDetails['email'],
        'billing_details[name]': billingDetails['name'],
        if (billingDetails['phone'] != null) 'billing_details[phone]': billingDetails['phone'],
      };

      final response = await _dio.post('/payment_methods', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Error creating payment method: $e');
    }
  }

  // Get payment intent status
  Future<Map<String, dynamic>> getPaymentIntent(String paymentIntentId) async {
    try {
      final response = await _dio.get('/payment_intents/$paymentIntentId');
      return response.data;
    } catch (e) {
      throw Exception('Error getting payment intent: $e');
    }
  }

  // Process refund
  Future<Map<String, dynamic>> processRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final formData = {
        'payment_intent': paymentIntentId,
        'amount': (amount * 100).round().toString(),
        if (reason != null) 'reason': reason,
      };

      final response = await _dio.post('/refunds', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Error processing refund: $e');
    }
  }
}
