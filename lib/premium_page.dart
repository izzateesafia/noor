import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../blocs/payment/payment_bloc.dart';
import '../models/payment/order_request.dart';
import '../models/payment/payment_plan.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedIndex = 0; // 0 for Apple Pay, 1 for Card
  bool _isApplePayAvailable = false;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Card details
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;
  
  // Form data
  final Map<String, dynamic> _formData = {};
  
  // Form key for credit card
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _checkApplePayAvailability();
    _loadPaymentPlans();
  }

  Future<void> _loadUserData() async {
    // Ensure user data is loaded
    final userCubit = context.read<UserCubit>();
    if (userCubit.state.status == UserStatus.initial) {
      await userCubit.fetchCurrentUser();
    }
  }

  Future<void> _checkApplePayAvailability() async {
    if (Platform.isIOS) {
      final isSupported = await Stripe.instance.isPlatformPaySupported();
      if (isSupported) {
        setState(() {
          _isApplePayAvailable = true;
        });
      } else {
        setState(() {
          _isApplePayAvailable = false;
        });
      }
    } else {
      setState(() {
        _isApplePayAvailable = false;
      });
    }
  }

  void _loadPaymentPlans() {
    context.read<PaymentBloc>().add(const LoadPaymentPlans());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        // Debug logging
        print('Premium Page BlocBuilder: UserState: $userState');
        print('Premium Page BlocBuilder: Status: ${userState.status}');
        print('Premium Page BlocBuilder: CurrentUser: ${userState.currentUser}');
        
        // Ensure user data is loaded if needed
        if (userState.status == UserStatus.initial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserCubit>().fetchCurrentUser();
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Premium Subscription'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message ?? 'Payment failed'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PaymentSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment successful! Welcome to Premium!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Refresh user data to get updated premium status
                context.read<UserCubit>().fetchCurrentUser();
                
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              if (state is PaymentLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (state is PaymentPlansLoaded) {
                return _buildPaymentPlans(state.plans);
              }
              
              return const Center(
                child: Text('Loading payment plans...'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentPlans(List<PaymentPlan> plans) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock all premium features and content',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Plans
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...plans.map((plan) => _buildPlanCard(plan)),
          
          const SizedBox(height: 24),
          
          // Payment Method Selection
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment Method Toggle
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                _buildToggleButton("🍎 Apple Pay", 0),
                _buildToggleButton("💳 Card", 1),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Form
          if (_selectedIndex == 1) _buildCardPaymentForm(),
          
          const SizedBox(height: 24),
          
          // Personal Information Form
          _buildPersonalInfoForm(),
          
          const SizedBox(height: 32),
          
          // Pay Button
          _buildPayButton(plans),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular 
              ? Colors.blue 
              : Theme.of(context).dividerColor.withOpacity(0.3),
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Handle plan selection
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'RM ${plan.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.blue 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      children: [
        CreditCardWidget(
          cardNumber: _cardNumber,
          expiryDate: _expiryDate,
          cardHolderName: _cardHolderName,
          cvvCode: _cvvCode,
          showBackView: _isCvvFocused,
          isHolderNameVisible: true,
          onCreditCardWidgetChange: (value) {},
        ),
        const SizedBox(height: 16),
        _CreditCardFormWidget(
          formKey: _formKey,
          onCardDataChanged: (cardNumber, expiryDate, cardHolderName, cvvCode, isCvvFocused) {
            setState(() {
              _cardNumber = cardNumber;
              _expiryDate = expiryDate;
              _cardHolderName = cardHolderName;
              _cvvCode = cvvCode;
              _isCvvFocused = isCvvFocused;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _formData['first_name'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _formData['last_name'] = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => _formData['email'] = value,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => _formData['phone_number'] = value,
        ),
      ],
    );
  }

  Widget _buildPayButton(List<PaymentPlan> plans) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _processPayment(plans),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Subscribe Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(List<PaymentPlan> plans) async {
    // Use BlocBuilder to ensure we have access to UserCubit
    final userState = context.read<UserCubit>().state;
    final userId = userState.currentUser?.id;
    
    // Debug logging
    print('Premium Page: UserState: $userState');
    print('Premium Page: CurrentUser: ${userState.currentUser}');
    print('Premium Page: UserId: $userId');
    print('Premium Page: UserStatus: ${userState.status}');
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase premium')),
      );
      return;
    }

    // Get selected plan (for now, use the first plan)
    final selectedPlan = plans.first;
    
    // Validate form
    if (!_validateForm()) {
      return;
    }

    // Create order request
    final orderRequest = OrderRequest(
      userId: userId,
      planId: selectedPlan.id,
      amount: selectedPlan.price,
      currency: selectedPlan.currency,
      description: 'Premium subscription - ${selectedPlan.name}',
      email: _formData['email'],
      fullName: '${_formData['first_name']} ${_formData['last_name']}',
      phoneNumber: _formData['phone_number'],
      paymentMethod: _selectedIndex == 0 ? 'apple_pay' : 'card',
    );

    // Create card details if using card payment
    CardDetails? cardDetails;
    if (_selectedIndex == 1) {
      final expiryParts = _expiryDate.split('/');
      if (expiryParts.length == 2) {
        cardDetails = CardDetails(
          number: _cardNumber.replaceAll(' ', ''),
          expirationMonth: int.parse(expiryParts[0]),
          expirationYear: int.parse('20${expiryParts[1]}'),
          cvc: _cvvCode,
        );
      }
    }

    // Process payment
    context.read<PaymentBloc>().add(
      InitPayment(
        cardDetails: cardDetails,
        orderRequest: orderRequest,
        totalAmount: selectedPlan.price.toStringAsFixed(2),
        planId: selectedPlan.id,
      ),
    );
  }

  bool _validateForm() {
    if (_formData['first_name'] == null || _formData['first_name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name')),
      );
      return false;
    }
    
    if (_formData['last_name'] == null || _formData['last_name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your last name')),
      );
      return false;
    }
    
    if (_formData['email'] == null || _formData['email'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return false;
    }
    
    if (_formData['phone_number'] == null || _formData['phone_number'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return false;
    }

    if (_selectedIndex == 1) {
      if (_cardNumber.isEmpty || _expiryDate.isEmpty || _cardHolderName.isEmpty || _cvvCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter complete card details')),
        );
        return false;
      }
    }

    return true;
  }
}

class _CreditCardFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(String, String, String, String, bool) onCardDataChanged;

  const _CreditCardFormWidget({
    required this.formKey,
    required this.onCardDataChanged,
  });

  @override
  State<_CreditCardFormWidget> createState() => _CreditCardFormWidgetState();
}

class _CreditCardFormWidgetState extends State<_CreditCardFormWidget> {
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;

  @override
  Widget build(BuildContext context) {
    return CreditCardForm(
      formKey: widget.formKey,
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
        
        // Notify parent widget
        widget.onCardDataChanged(_cardNumber, _expiryDate, _cardHolderName, _cvvCode, _isCvvFocused);
      },
      themeColor: Colors.blue,
    );
  }
}
