import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/payment_repository.dart';
import 'utils/toast_util.dart';

class CardInfoPage extends StatefulWidget {
  const CardInfoPage({super.key});

  @override
  State<CardInfoPage> createState() => _CardInfoPageState();
}

class _CardInfoPageState extends State<CardInfoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;
  bool _isLoading = false;

  String? _validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }
    // Remove spaces for validation
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Invalid card number';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }
    // Format: MM/YY
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }
    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) {
      return 'Invalid date';
    }
    
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }
    
    // Check if card is expired
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }
    
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3-4 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'CVV must be numeric';
    }
    return null;
  }

  String? _validateCardHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cardholder name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  Future<void> _saveCard() async {
    // Validate form (CreditCardForm has built-in validation)
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation checks
    final cardNumberError = _validateCardNumber(_cardNumber);
    final expiryError = _validateExpiryDate(_expiryDate);
    final cvvError = _validateCVV(_cvvCode);
    final nameError = _validateCardHolderName(_cardHolderName);

    if (cardNumberError != null ||
        expiryError != null ||
        cvvError != null ||
        nameError != null) {
      String errorMessage = 'Please fix the following errors:\n';
      if (cardNumberError != null) errorMessage += '• $cardNumberError\n';
      if (expiryError != null) errorMessage += '• $expiryError\n';
      if (cvvError != null) errorMessage += '• $cvvError\n';
      if (nameError != null) errorMessage += '• $nameError\n';
      ToastUtil.showError(context, errorMessage.trim());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userState = context.read<UserCubit>().state;
      final user = userState.currentUser;

      if (user == null) {
        ToastUtil.showError(context, 'User not found. Please log in again.');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Parse expiry date
      final expiryParts = _expiryDate.split('/');
      final month = int.parse(expiryParts[0]);
      final year = 2000 + int.parse(expiryParts[1]); // Convert YY to YYYY

      // Prepare card data
      final cardData = {
        'number': _cardNumber.replaceAll(' ', ''),
        'exp_month': month,
        'exp_year': year,
        'cvc': _cvvCode,
      };

      // Prepare billing details
      // Only include phone if it's valid (not null, not empty, not "N/A")
      final billingDetails = {
        'email': user.email,
        'name': user.name,
        if (user.phone.isNotEmpty && user.phone != 'N/A') 'phone': user.phone,
      };

      // Create payment method via repository
      final paymentRepo = PaymentRepository();
      final paymentMethod = await paymentRepo.createPaymentMethod(
        cardData: cardData,
        billingDetails: billingDetails,
      );

      // Extract payment method ID
      final paymentMethodId = paymentMethod['id'] as String?;

      if (paymentMethodId == null) {
        throw Exception('Failed to create payment method');
      }

      // Update user with payment method ID
      final updatedUser = user.copyWith(
        stripePaymentMethodId: paymentMethodId,
      );

      await context.read<UserCubit>().updateUser(updatedUser);

      if (mounted) {
        ToastUtil.showSuccess(context, 'Card saved successfully!');
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save card. Please try again.';
        final errorString = e.toString().toLowerCase();
        
        // Check for specific Stripe error codes
        if (errorString.contains('card_declined')) {
          errorMessage = 'Card was declined. Please check your card details or try a different card.';
        } else if (errorString.contains('expired_card')) {
          errorMessage = 'Card has expired. Please use a different card.';
        } else if (errorString.contains('incorrect_cvc') || errorString.contains('cvc')) {
          errorMessage = 'Incorrect CVV. Please check and try again.';
        } else if (errorString.contains('invalid_number') || errorString.contains('invalid card')) {
          errorMessage = 'Invalid card number. Please check and try again.';
        } else if (errorString.contains('status code of 402')) {
          errorMessage = 'Unable to save card. Please check your payment settings or contact support.';
        } else if (errorString.contains('status code of 401')) {
          errorMessage = 'Authentication error. Please contact support.';
        } else if (errorString.contains('status code of 400')) {
          errorMessage = 'Invalid card details. Please check all fields and try again.';
        } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (errorString.contains('stripe error')) {
          // Extract the Stripe error message if available
          final match = RegExp(r'Stripe error: (.+?)(?: \(Code:|\s*$)').firstMatch(errorString);
          if (match != null) {
            errorMessage = match.group(1) ?? 'Stripe error occurred. Please try again.';
          } else {
            errorMessage = 'Payment processing error. Please try again or contact support.';
          }
        } else {
          // Show more detailed error for debugging (but user-friendly)
          print('Card save error: $e');
          errorMessage = 'Unable to save card. Please verify your card details and try again.';
        }
        ToastUtil.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state.status == UserStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and subtitle
                Text(
                  'Save Card for Faster Checkout',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional - You can add this later',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Credit card widget (visual card)
                CreditCardWidget(
                  cardNumber: _cardNumber,
                  expiryDate: _expiryDate,
                  cardHolderName: _cardHolderName,
                  cvvCode: _cvvCode,
                  showBackView: _isCvvFocused,
                  isHolderNameVisible: true,
                  onCreditCardWidgetChange: (value) {},
                ),
                const SizedBox(height: 24),

                // Credit card form (CreditCardForm creates its own Form internally)
                CreditCardForm(
                  formKey: _formKey,
                  cardNumber: _cardNumber,
                  expiryDate: _expiryDate,
                  cardHolderName: _cardHolderName,
                  cvvCode: _cvvCode,
                  onCreditCardModelChange: (creditCardModel) {
                    setState(() {
                      _cardNumber = creditCardModel.cardNumber;
                      _expiryDate = creditCardModel.expiryDate;
                      _cardHolderName = creditCardModel.cardHolderName;
                      _cvvCode = creditCardModel.cvvCode;
                      _isCvvFocused = creditCardModel.isCvvFocused;
                    });
                  },
                  themeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    // Skip button (less prominent)
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : _skip,
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Confirm button (prominent)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Card',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

