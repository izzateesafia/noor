import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'models/payment/order.dart' as payment_models;
import 'models/class_model.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'blocs/payment/payment_bloc.dart';
import 'cubit/class_cubit.dart';
import 'cubit/class_states.dart';
import 'repository/user_repository.dart';
import 'repository/class_repository.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit(UserRepository())..fetchCurrentUser()),
        BlocProvider(create: (_) => PaymentBloc()),
        BlocProvider(create: (_) => ClassCubit(ClassRepository())),
      ],
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatefulWidget {
  const _UserProfileView();

  @override
  State<_UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<_UserProfileView> {
  @override
  void initState() {
    super.initState();
    // Fetch payment history and subscription after user is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userCubit = context.read<UserCubit>();
      if (userCubit.state.currentUser != null) {
        final userId = userCubit.state.currentUser!.id;
        context.read<PaymentBloc>().add(LoadUserOrders(userId: userId));
        // Fetch classes to display enrolled classes
        context.read<ClassCubit>().fetchClasses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        final user = userState.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            actions: [
              if (user.isPremium)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: const Text('Premium', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.amber,
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                _buildUserInfo(user),
                const SizedBox(height: 32),
                
                // Subscription Info
                BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, paymentState) {
                    if (paymentState is UserOrdersLoaded && paymentState.orders.isNotEmpty) {
                      return _buildSubscriptionInfo(paymentState.orders.first);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                if (user.isPremium) 
                  const SizedBox(height: 32),
                
                // Enrolled Classes
                _buildEnrolledClasses(user),
                const SizedBox(height: 32),
                
                // Payment History
                _buildPaymentHistory(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.name, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          Text(
            user.email, 
            style: TextStyle(color: Colors.grey[700])
          ),
          if (user.phone.isNotEmpty)
            Text(
              user.phone, 
              style: TextStyle(color: Colors.grey[700])
            ),
          if (user.address != null && user.address!.isNotEmpty)
            Text(
              user.address!, 
              style: TextStyle(color: Colors.grey[700])
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(payment_models.Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Active Subscription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Plan', order.description ?? 'Premium Subscription'),
            _buildInfoRow('Price', 'RM${order.amount?.toStringAsFixed(2) ?? '0.00'} ${order.currency?.toUpperCase() ?? 'MYR'}'),
            _buildInfoRow('Order ID', order.id ?? 'N/A'),
            _buildInfoRow('Created', DateFormat('MMM dd, yyyy').format(order.createdAt ?? DateTime.now())),
            _buildInfoRow('Status', order.status?.toUpperCase() ?? 'UNKNOWN'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledClasses(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Enrolled Classes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${user.enrolledClassIds.length}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<ClassCubit, ClassState>(
          builder: (context, classState) {
            if (classState.status == ClassStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (classState.status == ClassStatus.error) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading enrolled classes',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ClassCubit>().fetchClasses();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Filter only enrolled classes
            final enrolledClasses = classState.classes
                .where((classModel) => user.enrolledClassIds.contains(classModel.id))
                .toList();

            if (enrolledClasses.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.school, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No classes enrolled yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can enroll in classes from the main menu.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/classes');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Browse Classes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Enrolled Classes List
                ...enrolledClasses.map((classModel) => _buildEnrolledClassCard(classModel)).toList(),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/classes');
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('View All Classes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnrolledClassCard(ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(Icons.school, color: Colors.blue, size: 24),
        ),
        title: Text(
          classModel.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${classModel.instructor} • ${classModel.level}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '${classModel.time} • ${classModel.duration}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: classModel.price > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            classModel.price > 0 ? '\$${classModel.price.toStringAsFixed(2)}' : 'Free',
            style: TextStyle(
              color: classModel.price > 0 ? Colors.orange[700] : Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, paymentState) {
            if (paymentState is PaymentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (paymentState is PaymentError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading payments',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final userCubit = context.read<UserCubit>();
                          if (userCubit.state.currentUser != null) {
                            context.read<PaymentBloc>().add(LoadUserOrders(userId: userCubit.state.currentUser!.id));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (paymentState is! UserOrdersLoaded || paymentState.orders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No payments found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your payment history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Payment Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPaymentStat('Total', paymentState.orders.length.toString()),
                        _buildPaymentStat('Successful', paymentState.orders.where((o) => o.status == 'completed').length.toString()),
                        _buildPaymentStat('Total Spent', 'RM${paymentState.orders.fold(0.0, (sum, o) => sum + (o.amount ?? 0)).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Payment List
                ...paymentState.orders.map((order) => _buildPaymentCard(order)).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(payment_models.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPaymentStatusColor(order.status).withOpacity(0.1),
          child: Icon(
            _getPaymentStatusIcon(order.status),
            color: _getPaymentStatusColor(order.status),
          ),
        ),
        title: Text(
          '${order.description ?? 'Payment'} - RM${order.amount?.toStringAsFixed(2) ?? '0.00'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.currency?.toUpperCase() ?? 'MYR'} • ${DateFormat('MMM dd, yyyy').format(order.createdAt ?? DateTime.now())}',
            ),
            if (order.description != null)
              Text(
                order.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.status?.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                color: _getPaymentStatusColor(order.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              'Card',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'initial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'initial':
        return Icons.info;
      default:
        return Icons.info;
    }
  }
} 