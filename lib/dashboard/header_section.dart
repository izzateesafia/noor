import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_constants.dart';
import '../models/user_model.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import 'package:intl/intl.dart';
import '../user_profile_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HeaderSection extends StatelessWidget {
  final UserModel user;
  
  const HeaderSection({super.key, required this.user});

    void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Keluar'),
          content: const Text('Adakah anda pasti mahu log keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await context.read<UserCubit>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal log keluar: $e')),
                    );
                  }
                }
              },
              child: const Text('Log Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = user.name;
    final String greeting = 'Assalamualaikum, $userName!';
    final String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    
    // Debug logging
    print('HeaderSection: Building with user: ${user.name} (${user.email})');
    print('HeaderSection: Greeting: $greeting');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                          // Profile icon button (replaces app/flash icon)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: const Icon(Icons.account_circle),
                    tooltip: 'Profile',
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UserProfilePage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Sign Out button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign Out',
                    color: Colors.white,
                    onPressed: () => _showSignOutDialog(context),
                  ),
                ),
          const SizedBox(width: 20),
          // Greeting and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                // Location display
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    final currentUser = state.currentUser;
                    final locationName = currentUser?.locationName;
                    
                    // Debug logging
                    print('HeaderSection: Building location display');
                    print('HeaderSection: Current user: ${currentUser?.name}');
                    print('HeaderSection: Location name: $locationName');
                    print('HeaderSection: Latitude: ${currentUser?.latitude}, Longitude: ${currentUser?.longitude}');
                    
                    if (locationName != null && locationName.isNotEmpty) {
                      return Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return InkWell(
                        onTap: () async {
                          // Open app settings
                          await openAppSettings();
                          // The lifecycle observer in dashboard_page.dart will handle
                          // fetching location when the app resumes
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Location not available',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 