import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment/order.dart' as payment_models;
import '../models/payment/payment_plan.dart';
import '../services/payment_service.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  // Create order
  Future<payment_models.Order> createOrder({
    required String userId,
    required String planId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      // Create payment intent with Stripe
      final paymentIntent = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: currency,
        userId: userId,
        description: description ?? 'Premium subscription',
        metadata: {
          'plan_id': planId,
          'type': planId.startsWith('class_') ? 'class_enrollment' : 'subscription',
        },
      );

      // Create order document in Firestore
      final orderData = {
        'userId': userId,
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'description': description ?? 'Premium subscription',
        'status': 'pending',
        'paymentIntentId': paymentIntent['id'],
        'secretKey': paymentIntent['client_secret'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);
      
      return payment_models.Order.fromJson({
        'id': docRef.id,
        ...orderData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get user orders
  Future<List<payment_models.Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return payment_models.Order.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt']?.toDate()?.toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Error fetching user orders: $e');
    }
  }

  // Get order by ID
  Future<payment_models.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return payment_models.Order.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt']?.toDate()?.toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  // Get available payment plans
  Future<List<PaymentPlan>> getAvailablePlans() async {
    try {
      // For now, return hardcoded payment plans
      // In production, you would fetch from Firestore
      return [
        const PaymentPlan(
          id: 'monthly',
          name: 'Monthly Premium',
          description: 'Access to all premium features for one month',
          price: 9.90,
          currency: 'MYR',
          interval: 'monthly',
          features: [
            'Unlock all Rukun Solat videos',
            'Ad-free experience',
            'Priority support',
            'Exclusive content access',
          ],
          isPopular: false,
        ),
        const PaymentPlan(
          id: 'yearly',
          name: 'Yearly Premium',
          description: 'Access to all premium features for one year',
          price: 99.00,
          currency: 'MYR',
          interval: 'yearly',
          features: [
            'Unlock all Rukun Solat videos',
            'Ad-free experience',
            'Priority support',
            'Exclusive content access',
            'Save 17% compared to monthly',
          ],
          isPopular: true,
        ),
      ];
      
      // Uncomment this code when you have payment plans in Firestore:
      /*
      final snapshot = await _firestore
          .collection('payment_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PaymentPlan.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      */
    } catch (e) {
      throw Exception('Error fetching payment plans: $e');
    }
  }

  // Initialize default payment plans
  Future<void> initializeDefaultPlans() async {
    try {
      final defaultPlans = [
        PaymentPlan(
          id: 'monthly',
          name: 'Monthly Premium',
          description: 'Perfect for getting started',
          price: 9.90,
          currency: 'MYR',
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
          description: 'Best value - Save 17%',
          price: 99.00,
          currency: 'MYR',
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
          price: 299.00,
          currency: 'MYR',
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
        await _firestore.collection('payment_plans').doc(plan.id).set({
          'name': plan.name,
          'description': plan.description,
          'price': plan.price,
          'currency': plan.currency,
          'interval': plan.interval,
          'features': plan.features,
          'isPopular': plan.isPopular,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Error initializing default plans: $e');
    }
  }

  // Update user class enrollment
  Future<void> updateUserClassEnrollment({
    required String userId,
    required String classId,
  }) async {
    try {
      print('PaymentRepository: Attempting to enroll user $userId in class $classId');
      
      await _firestore.collection('users').doc(userId).update({
        'enrolledClassIds': FieldValue.arrayUnion([classId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('PaymentRepository: User $userId enrolled in class $classId');
      
      // Verify the update by reading the document
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final enrolledClassIds = List<String>.from(data['enrolledClassIds'] ?? []);
        print('PaymentRepository: Verified - User $userId enrolled classes: $enrolledClassIds');
      }
    } catch (e) {
      print('Error updating user class enrollment: $e');
      rethrow;
    }
  }

  // Update user premium status
  Future<void> updateUserPremiumStatus({
    required String userId,
    required bool isPremium,
    required DateTime premiumExpiryDate,
    required String planId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremium': isPremium,
        'premiumExpiryDate': premiumExpiryDate.toIso8601String(),
        'premiumPlanId': planId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user premium status: $e');
    }
  }

  // Confirm payment
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      return await _paymentService.confirmPaymentIntent(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );
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
      return await _paymentService.createPaymentMethod(
        cardData: cardData,
        billingDetails: billingDetails,
      );
    } catch (e) {
      throw Exception('Error creating payment method: $e');
    }
  }
}
