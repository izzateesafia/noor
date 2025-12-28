import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static PaymentService? _instance;
  late Dio _dio;

  factory PaymentService() => _instance ??= PaymentService._();

  PaymentService._() {
    // Get Stripe secret key from environment variables
    final stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
    
    if (stripeSecretKey.isEmpty) {
      throw Exception('STRIPE_SECRET_KEY is not set in .env file');
    }
    
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.stripe.com/v1',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $stripeSecretKey',
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
    String? paymentMethodId, // Optional: use saved payment method
  }) async {
    try {
      final formData = {
        'amount': (amount * 100).round().toString(), // Convert to cents
        'currency': currency.toLowerCase(),
        'metadata[user_id]': userId,
        if (description != null) 'description': description,
      };

      // If payment method ID is provided, attach it to the payment intent
      if (paymentMethodId != null) {
        formData['payment_method'] = paymentMethodId;
        formData['confirm'] = 'true'; // Auto-confirm if payment method is attached
        formData['return_url'] = 'your-app://payment-return'; // For 3D Secure if needed
      } else {
        // Use automatic payment methods if no saved payment method
        formData['automatic_payment_methods[enabled]'] = 'true';
      }

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
        'billing_details[email]': billingDetails['email'] ?? '',
        'billing_details[name]': billingDetails['name'] ?? '',
      };

      // Only add phone if it's valid (not null, not empty, not "N/A")
      final phone = billingDetails['phone'];
      if (phone != null && phone.toString().trim().isNotEmpty && phone.toString().trim() != 'N/A') {
        formData['billing_details[phone]'] = phone.toString().trim();
      }

      final response = await _dio.post('/payment_methods', data: formData);
      return response.data;
    } on DioException catch (e) {
      // Handle DioException with better error messages
      String errorMessage = 'Error creating payment method';
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        
        // Extract Stripe error message if available
        if (errorData is Map<String, dynamic>) {
          final error = errorData['error'];
          if (error is Map<String, dynamic>) {
            final message = error['message'] as String?;
            final code = error['code'] as String?;
            
            if (message != null) {
              errorMessage = 'Stripe error: $message';
              if (code != null) {
                errorMessage += ' (Code: $code)';
              }
            }
          }
        }
        
        // Provide user-friendly messages for common status codes
        if (statusCode == 402) {
          errorMessage = 'Payment method creation failed. Please check your Stripe account configuration or try a different card.';
        } else if (statusCode == 401) {
          errorMessage = 'Authentication failed. Please check your Stripe API key.';
        } else if (statusCode == 400) {
          errorMessage = 'Invalid card details. Please check your card information and try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Connection error. Please check your internet connection and try again.';
      }
      
      throw Exception('$errorMessage (Status: ${e.response?.statusCode ?? 'Unknown'})');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
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
