import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../repository/user_repository.dart';
import 'user_detail_page.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the existing UserCubit for admin check
    final existingUserCubit = context.read<UserCubit>();
    
    return BlocProvider(
      create: (_) => UserCubit(UserRepository())..fetchUsers(),
      child: BlocBuilder<UserCubit, UserState>(
        bloc: existingUserCubit,
        builder: (context, state) {
          // Check if current user is admin using the existing UserCubit
          final currentUser = state.currentUser;
          final isAdmin = currentUser?.roles.contains(UserType.admin) ?? false;
          
          if (!isAdmin) {
            // Non-admin users should not access this page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akses ditolak: Hanya admin boleh mengakses halaman ini.'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            return Scaffold(
              appBar: AppBar(
                title: const Text('Urus Pengguna'),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return const _ManageUsersView();
        },
      ),
    );
  }
}

class _ManageUsersView extends StatefulWidget {
  const _ManageUsersView();

  @override
  State<_ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<_ManageUsersView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch users when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCubit>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _viewUserDetails(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailPage(user: user),
      ),
    );
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Pengguna'),
        content: Text('Adakah anda pasti mahu memadam ${user.name}? Tindakan ini tidak boleh dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<UserCubit>().deleteUser(user.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Padam', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _assignAsJurulatih(UserModel user) async {
    // Check if user already has trainer role
    if (user.roles.contains(UserType.trainer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} sudah mempunyai peranan Jurulatih.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tugaskan sebagai Jurulatih'),
        content: Text('Adakah anda pasti mahu menugaskan ${user.name} sebagai Jurulatih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Tugaskan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Add trainer role as primary (first in array)
    final updatedRoles = [
      UserType.trainer,
      ...user.roles.where((r) => r != UserType.trainer),
    ];

    final updatedUser = user.copyWith(roles: updatedRoles);

    try {
      await context.read<UserCubit>().updateUser(updatedUser);
      // Refresh users list
      await context.read<UserCubit>().fetchUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} telah ditugaskan sebagai Jurulatih.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menugaskan peranan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _assignAsMasterTrainer(UserModel user) async {
    // Check if user already has masterTrainer role
    if (user.roles.contains(UserType.masterTrainer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} sudah mempunyai peranan Master Trainer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tugaskan sebagai Master Trainer'),
        content: Text('Adakah anda pasti mahu menugaskan ${user.name} sebagai Master Trainer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Tugaskan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Add masterTrainer role as primary (first in array)
    final updatedRoles = [
      UserType.masterTrainer,
      ...user.roles.where((r) => r != UserType.masterTrainer),
    ];

    final updatedUser = user.copyWith(roles: updatedRoles);

    try {
      await context.read<UserCubit>().updateUser(updatedUser);
      // Refresh users list
      await context.read<UserCubit>().fetchUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} telah ditugaskan sebagai Master Trainer.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menugaskan peranan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get role badges for display
  List<Widget> _getRoleBadges(UserModel user) {
    final badges = <Widget>[];
    
    if (user.roles.contains(UserType.admin)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Text(
            'Admin',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    if (user.roles.contains(UserType.masterTrainer)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Text(
            'Master Trainer',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    if (user.roles.contains(UserType.trainer)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Text(
            'Jurulatih',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return badges;
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((user) {
      final query = _searchQuery.toLowerCase();
      // Search in address map values
      bool addressMatches = false;
      if (user.address != null) {
        final addressStr = user.address!.values
            .where((v) => v.isNotEmpty)
            .join(' ')
            .toLowerCase();
        addressMatches = addressStr.contains(query);
      }
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          addressMatches;
    }).toList();
  }

  /// Format address map as a readable string for display
  String _formatAddressForDisplay(Map<String, String>? address) {
    if (address == null) return '';
    final parts = <String>[];
    if (address['line1']?.isNotEmpty ?? false) parts.add(address['line1']!);
    if (address['street']?.isNotEmpty ?? false) parts.add(address['street']!);
    if (address['postcode']?.isNotEmpty ?? false) parts.add(address['postcode']!);
    if (address['city']?.isNotEmpty ?? false) parts.add(address['city']!);
    if (address['state']?.isNotEmpty ?? false) parts.add(address['state']!);
    if (address['country']?.isNotEmpty ?? false) parts.add(address['country']!);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Urus Pengguna'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          ),
          body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Users list
          Expanded(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                if (state.status == UserStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == UserStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.error}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<UserCubit>().fetchUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredUsers = _filterUsers(state.users);

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No users found'
                              : 'No users match your search',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.75,
                          children: [
                            // Assign as Jurulatih
                            SlidableAction(
                              onPressed: (_) => _assignAsJurulatih(user),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.person_add,
                              label: user.roles.contains(UserType.trainer) 
                                  ? 'Already Jurulatih' 
                                  : 'Assign Jurulatih',
                              flex: 2,
                            ),
                            // Assign as Master Trainer
                            SlidableAction(
                              onPressed: (_) => _assignAsMasterTrainer(user),
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              icon: Icons.star,
                              label: user.roles.contains(UserType.masterTrainer)
                                  ? 'Already Master'
                                  : 'Assign Master',
                              flex: 2,
                            ),
                            // Delete user
                            SlidableAction(
                              onPressed: (_) => _deleteUser(user),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                              flex: 1,
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: user.roles.contains(UserType.admin)
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                user.roles.contains(UserType.admin)
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: user.roles.contains(UserType.admin)
                                    ? Colors.red
                                    : Colors.blue,
                                size: 28,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (user.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Premium',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                // Role badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _getRoleBadges(user),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.phone,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.address != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatAddressForDisplay(user.address),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.class_,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user.enrolledClassIds.length} classes enrolled',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _viewUserDetails(user),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
        );
      },
    );
  }
} 