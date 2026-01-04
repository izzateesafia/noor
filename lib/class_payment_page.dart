import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import 'models/class_model.dart';
import 'models/payment/order_request.dart';
import 'blocs/payment/payment_bloc.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';

class ClassPaymentPage extends StatefulWidget {
  final ClassModel classModel;
  final UserModel user;
  const ClassPaymentPage({super.key, required this.classModel, required this.user});

  @override
  State<ClassPaymentPage> createState() => _ClassPaymentPageState();
}

class _ClassPaymentPageState extends State<ClassPaymentPage> {
  int _selectedIndex = 0; // 0 for Apple Pay, 1 for Card
  
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
    _prefillUserData();
  }

  void _prefillUserData() {
    _firstNameController.text = widget.user.name.split(' ').first;
    _lastNameController.text = widget.user.name.split(' ').length > 1 
        ? widget.user.name.split(' ').skip(1).join(' ') 
        : '';
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone;
    
    _formData['first_name'] = _firstNameController.text;
    _formData['last_name'] = _lastNameController.text;
    _formData['email'] = _emailController.text;
    _formData['phone_number'] = _phoneController.text;
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
        // Ensure user data is loaded if needed
        if (userState.status == UserStatus.initial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserCubit>().fetchCurrentUser();
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pembayaran Kelas'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message ?? 'Pembayaran gagal'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else if (state is PaymentSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pembayaran berjaya! Anda kini telah mendaftar kelas ini.'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              if (state is PaymentLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              return _buildPaymentContent(userState);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentContent(UserState userState) {
    // Check if user is enrolled in this class
    final currentUser = userState.currentUser;
    final isEnrolled = currentUser?.enrolledClassIds.contains(widget.classModel.id) ?? false;
    final isPaymentPending = currentUser?.isPaymentPendingForClass(widget.classModel.id) ?? false;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Image at Top
          if (widget.classModel.image != null && widget.classModel.image!.isNotEmpty)
            _buildClassImage(),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Information
                _buildClassInfo(),
                const SizedBox(height: 24),

                // Show enrollment status if enrolled, otherwise show payment button or pending status
                if (isEnrolled)
                  _buildEnrollmentStatus()
                else if (isPaymentPending)
                  _buildPendingPaymentStatus()
                else
                  _buildOnPayButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassImage() {
    return ClipRRect(
      child: Image.network(
        widget.classModel.image!,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 250,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 250,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassInfo() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classModel.title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengajar: ${widget.classModel.instructor}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.classModel.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Jumlah:',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'RM ${widget.classModel.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    final userState = context.read<UserCubit>().state;
    final savedPaymentMethodId = userState.currentUser?.stripePaymentMethodId;
    final hasSavedCard = savedPaymentMethodId != null && savedPaymentMethodId.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kaedah Pembayaran',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        
        // Show saved card option if available
        if (hasSavedCard) ...[
          _buildSavedCardOption(),
          const SizedBox(height: 12),
        ],
        
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _buildToggleButton("Apple Pay", 0),
              _buildToggleButton("Kad", 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCardOption() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2; // Use saved card
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedIndex == 2 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedIndex == 2 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: _selectedIndex == 2 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: _selectedIndex == 2 ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guna Kad Tersimpan',
                    style: TextStyle(
                      color: _selectedIndex == 2 ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Bayar dengan kad yang telah disimpan',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedIndex == 2)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
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
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color,
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
          'Maklumat Peribadi',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pertama',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                onChanged: (value) => _formData['first_name'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Akhir',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                onChanged: (value) => _formData['last_name'] = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'E-mel',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => _formData['email'] = value,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Nombor Telefon',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => _formData['phone_number'] = value,
        ),
      ],
    );
  }

  Widget _buildPendingPaymentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.orange[700],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Menunggu pengesahan admin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran anda sedang menunggu pengesahan daripada pihak admin. Sila tunggu untuk kemas kini.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Anda telah mendaftar kelas ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Terima kasih kerana mendaftar. Anda kini boleh mengakses semua kandungan kelas ini.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOnPayButton() {
    final userState = context.read<UserCubit>().state;
    final currentUser = userState.currentUser;
    final isPaymentPending = currentUser?.isPaymentPendingForClass(widget.classModel.id) ?? false;
    final hasPaymentUrl = widget.classModel.paymentUrl != null && 
                         widget.classModel.paymentUrl!.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment),
        label: Text('Bayar RM ${widget.classModel.price.toStringAsFixed(2)}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: (hasPaymentUrl && !isPaymentPending)
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.5),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: (hasPaymentUrl && !isPaymentPending) ? () => _launchPaymentUrl() : null,
      ),
    );
  }

  Future<void> _markPaymentAsPending() async {
    final userState = context.read<UserCubit>().state;
    final currentUser = userState.currentUser;
    
    if (currentUser == null) return;

    try {
      // Create or update pendingClassPayments map
      final updatedPendingPayments = Map<String, String>.from(
        currentUser.pendingClassPayments ?? {},
      );
      updatedPendingPayments[widget.classModel.id] = 'pending_confirmation';

      // Update user with pending payment status
      final updatedUser = currentUser.copyWith(
        pendingClassPayments: updatedPendingPayments,
      );

      await context.read<UserCubit>().updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status pembayaran telah dikemaskini. Sila tunggu pengesahan daripada pihak admin.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mengemaskini status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchPaymentUrl() async {
    if (widget.classModel.paymentUrl == null || 
        widget.classModel.paymentUrl!.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(widget.classModel.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        // Launch payment URL in in-app webview
        final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        
        // Show dialog when user returns from webview
        if (launched && mounted) {
          await Future.delayed(const Duration(milliseconds: 300)); // Small delay to ensure smooth transition
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pembayaran'),
                content: const Text('Adakah anda telah membuat pembayaran?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('belum'),
                    child: const Text('Belum bayar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('telah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Saya telah bayar'),
                  ),
                ],
              ),
            ).then((result) async {
              if (result == 'telah' && mounted) {
                // User confirmed payment - update pending status
                await _markPaymentAsPending();
              }
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak dapat membuka pautan pembayaran'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat membuka pautan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment),
        label: Text('Bayar RM ${widget.classModel.price.toStringAsFixed(2)}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () => _processPayment(),
      ),
    );
  }

  Future<void> _processPayment() async {
    final userState = context.read<UserCubit>().state;
    final userId = userState.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila log masuk untuk membeli kelas')),
      );
      return;
    }

    // Validate form
    if (!_validateForm()) {
      return;
    }

    // Create order request for class payment
    final orderRequest = OrderRequest(
      userId: userId,
      planId: 'class_${widget.classModel.id}', // Use class ID as plan ID
      amount: widget.classModel.price,
      currency: 'MYR',
      description: 'Class enrollment - ${widget.classModel.title}',
      email: _formData['email'],
      fullName: '${_formData['first_name']} ${_formData['last_name']}',
      phoneNumber: _formData['phone_number'],
      paymentMethod: _selectedIndex == 0 ? 'apple_pay' : 'card',
    );

    // Check if using saved payment method
    // final userState = context.read<UserCubit>().state;
    final savedPaymentMethodId = userState.currentUser?.stripePaymentMethodId;
    final useSavedCard = _selectedIndex == 2 && savedPaymentMethodId != null && savedPaymentMethodId.isNotEmpty;

    // Create card details if using new card payment
    stripe.CardDetails? cardDetails;
    String? paymentMethodId;
    
    if (useSavedCard) {
      // Use saved payment method
      paymentMethodId = savedPaymentMethodId;
    } else if (_selectedIndex == 1) {
      // Use new card details
      final expiryParts = _expiryDate.split('/');
      if (expiryParts.length == 2) {
        cardDetails = stripe.CardDetails(
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
        savedPaymentMethodId: paymentMethodId,
        orderRequest: orderRequest,
        totalAmount: widget.classModel.price.toStringAsFixed(2),
        planId: 'class_${widget.classModel.id}',
      ),
    );
  }

  bool _validateForm() {
    if (_formData['first_name'] == null || _formData['first_name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nama pertama anda')),
      );
      return false;
    }
    
    if (_formData['last_name'] == null || _formData['last_name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nama akhir anda')),
      );
      return false;
    }
    
    if (_formData['email'] == null || _formData['email'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan e-mel anda')),
      );
      return false;
    }
    
    if (_formData['phone_number'] == null || _formData['phone_number'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nombor telefon anda')),
      );
      return false;
    }

    // Skip card validation if using saved card
    if (_selectedIndex == 1) {
      if (_cardNumber.isEmpty || _expiryDate.isEmpty || _cardHolderName.isEmpty || _cvvCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila masukkan butiran kad lengkap')),
        );
        return false;
      }
    } else if (_selectedIndex == 2) {
      // Validate that saved payment method exists
      final userState = context.read<UserCubit>().state;
      final savedPaymentMethodId = userState.currentUser?.stripePaymentMethodId;
      if (savedPaymentMethodId == null || savedPaymentMethodId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiada kad tersimpan. Sila tambah kad terlebih dahulu.')),
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