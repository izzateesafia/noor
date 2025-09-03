import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentRepository {
  final _db = FirebaseFirestore.instance;
  
  // TODO: Replace with your actual Stripe keys
  final String _stripeSecretKey = 'sk_test_YOUR_STRIPE_SECRET_KEY_HERE';
  final String _stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE';
  final String _stripeBaseUrl = 'https://api.stripe.com/v1';

  // Create payment intent with Stripe
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Build request body
      final Map<String, String> body = {
        'amount': (amount * 100).round().toString(), // Convert to cents
        'currency': currency.toLowerCase(),
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
      };

      // Add metadata if provided
      if (metadata != null) {
        for (final entry in metadata.entries) {
          body['metadata[$entry.key]'] = entry.value.toString();
        }
      }

      final response = await http.post(
        Uri.parse('$_stripeBaseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Stripe API Error: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
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
      final response = await http.post(
        Uri.parse('$_stripeBaseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethodId,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Stripe API Error: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  // Save payment to Firestore
  Future<void> savePayment(Payment payment) async {
    try {
      final data = payment.toJson();
      data.remove('id');
      await _db.collection('payments').add(data);
    } catch (e) {
      throw Exception('Error saving payment to Firestore: $e');
    }
  }

  // Get user payments from Firestore
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final snapshot = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Payment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Error fetching user payments: $e');
    }
  }

  // Update payment status in Firestore
  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status, {String? errorMessage}) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': status.toString().split('.').last,
        'completedAt': status == PaymentStatus.completed ? DateTime.now().toIso8601String() : null,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }

  // Create subscription in Firestore
  Future<void> createSubscription(Subscription subscription) async {
    try {
      final data = subscription.toJson();
      data.remove('id');
      await _db.collection('subscriptions').add(data);
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  // Get user subscription from Firestore
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final snapshot = await _db
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return Subscription.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Error fetching user subscription: $e');
    }
  }

  // Cancel subscription in Firestore
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _db.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'endDate': DateTime.now().toIso8601String(),
        'status': PaymentStatus.cancelled.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }

  // Get available payment plans from Firestore
  Future<List<PaymentPlan>> getAvailablePlans() async {
    try {
      final snapshot = await _db
          .collection('payment_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentPlan.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Error fetching payment plans: $e');
    }
  }

  // Create payment plan in Firestore (for admin use)
  Future<void> createPaymentPlan(PaymentPlan plan) async {
    try {
      final data = plan.toJson();
      data.remove('id');
      await _db.collection('payment_plans').add(data);
    } catch (e) {
      throw Exception('Error creating payment plan: $e');
    }
  }

  // Process refund through Stripe
  Future<Map<String, dynamic>> processRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_stripeBaseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': paymentIntentId,
          'amount': (amount * 100).round().toString(),
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Stripe API Error: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error processing refund: $e');
    }
  }

  // Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics(String userId) async {
    try {
      final payments = await getUserPayments(userId);
      
      final totalSpent = payments
          .where((p) => p.status == PaymentStatus.completed)
          .fold(0.0, (sum, payment) => sum + payment.amount);
      
      final totalPayments = payments.length;
      final successfulPayments = payments.where((p) => p.status == PaymentStatus.completed).length;
      final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;
      
      return {
        'totalSpent': totalSpent,
        'totalPayments': totalPayments,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'successRate': totalPayments > 0 ? (successfulPayments / totalPayments) * 100.0 : 0.0,
      };
    } catch (e) {
      throw Exception('Error getting payment analytics: $e');
    }
  }

  // Initialize default payment plans (for first-time setup)
  Future<void> initializeDefaultPlans() async {
    try {
      final defaultPlans = [
        PaymentPlan(
          id: 'monthly',
          name: 'Monthly Premium',
          description: 'Perfect for getting started',
          price: 9.99,
          currency: 'USD',
          interval: 'monthly',
          features: [
            '✨ Unlimited access to all premium content',
            '📚 Exclusive Quran recitations',
            '🎓 Advanced Islamic courses',
            '🕌 Premium prayer times with notifications',
            '🚫 Ad-free experience',
            '💬 Priority customer support',
          ],
        ),
        PaymentPlan(
          id: 'yearly',
          name: 'Yearly Premium',
          description: 'Best value - Save 40%',
          price: 59.99,
          currency: 'USD',
          interval: 'yearly',
          features: [
            '✨ All monthly features',
            '🎁 2 months free',
            '📖 Exclusive Islamic books',
            '🎯 Personalized learning paths',
            '🌙 Special Ramadan content',
            '🕋 Virtual Hajj experience',
          ],
          isPopular: true,
        ),
        PaymentPlan(
          id: 'lifetime',
          name: 'Lifetime Premium',
          description: 'One-time payment, forever access',
          price: 199.99,
          currency: 'USD',
          interval: 'lifetime',
          features: [
            '✨ All yearly features',
            '♾️ Lifetime access',
            '👨‍👩‍👧‍👦 Family account (up to 5 users)',
            '📚 Complete Islamic library',
            '🎓 Certificate programs',
            '🤝 Personal spiritual advisor',
          ],
        ),
      ];

      for (final plan in defaultPlans) {
        await createPaymentPlan(plan);
      }
    } catch (e) {
      throw Exception('Error initializing default plans: $e');
    }
  }
} 