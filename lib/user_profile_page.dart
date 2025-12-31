import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/photo_permission_helper.dart';
import 'models/class_model.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'cubit/class_cubit.dart';
import 'cubit/class_states.dart';
import 'repository/user_repository.dart';
import 'repository/class_repository.dart';
import 'services/image_upload_service.dart';
import 'utils/toast_util.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Use existing cubits from parent context if available, otherwise create new ones
        BlocProvider<UserCubit>.value(
          value: context.read<UserCubit>(),
        ),
        BlocProvider<ClassCubit>.value(
          value: context.read<ClassCubit>(),
        ),
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
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Always fetch classes when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when page becomes visible (e.g., returning from payment)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCubit>().fetchCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, userState) {
        // Automatically fetch classes when user data is loaded
        if (userState.status == UserStatus.loaded && userState.currentUser != null) {
          // Only fetch classes if they haven't been loaded yet
          final classCubit = context.read<ClassCubit>();
          if (classCubit.state.status == ClassStatus.initial) {
            classCubit.fetchClasses();
          }
        }
      },
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          // Debug logging
          print('Profile Page BlocBuilder: UserState: $userState');
          print('Profile Page BlocBuilder: Status: ${userState.status}');
          print('Profile Page BlocBuilder: CurrentUser: ${userState.currentUser}');
          
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
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/premium');
                    },
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Upgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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
                
                // Enrolled Classes
                _buildEnrolledClasses(user),
                const SizedBox(height: 32),
                
                // Logout Button
                _buildLogoutButton(),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.profileImage != null
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    onPressed: _isUploadingImage ? null : () => _showImagePickerDialog(user),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.name, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          if (user.locationName != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  user.locationName!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            user.email, 
            style: TextStyle(color: Colors.grey[700])
          ),
          if (user.phone.isNotEmpty)
            Text(
              user.phone, 
              style: TextStyle(color: Colors.grey[700])
            ),
          if (user.address != null)
            Text(
              _formatAddressForDisplay(user.address), 
              style: TextStyle(color: Colors.grey[700])
            ),
        ],
      ),
    );
  }

  Future<void> _showImagePickerDialog(UserModel user) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndUploadImage(source, user);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source, UserModel user) async {
    try {
      // Check permission using helper
      final hasPermission = await PhotoPermissionHelper.checkAndRequestPhotoPermission(
        context,
        source: source,
      );
      if (!hasPermission) {
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      // Upload to Firebase Storage
      final imageUrl = await _imageUploadService.uploadProfilePicture(
        File(pickedFile.path),
      );

      // Delete old profile picture if exists
      if (user.profileImage != null) {
        try {
          await _imageUploadService.deleteProfilePicture(user.profileImage!);
        } catch (e) {
          print('Error deleting old profile picture: $e');
        }
      }

      // Update user in Firestore
      final updatedUser = user.copyWith(profileImage: imageUrl);
      await context.read<UserCubit>().updateUser(updatedUser);

      if (mounted) {
        ToastUtil.showSuccess(context, 'Gambar profil berjaya dikemas kini');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Gagal memuat naik gambar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildEnrolledClasses(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Kelas Yang Didaftar',
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
            const Spacer(),
            IconButton(
              onPressed: () {
                // Refresh user data and classes
                context.read<UserCubit>().fetchCurrentUser();
                context.read<ClassCubit>().fetchClasses();
              },
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Muat Semula',
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
                        'Ralat memuatkan kelas yang didaftar',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ClassCubit>().fetchClasses();
                        },
                        child: const Text('Cuba Lagi'),
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

            // Debug logging
            print('Profile Page: User enrolledClassIds: ${user.enrolledClassIds}');
            print('Profile Page: Available classes: ${classState.classes.map((c) => c.id).toList()}');
            print('Profile Page: Enrolled classes found: ${enrolledClasses.map((c) => c.title).toList()}');

            if (enrolledClasses.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.school, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kelas yang didaftar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda boleh mendaftar kelas dari menu utama.',
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
                        label: const Text('Jelajah Kelas'),
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
                    label: const Text('Lihat Semua Kelas'),
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

  Widget _buildLogoutButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Keluar'),
          content: const Text('Adakah anda pasti mahu log keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await context.read<UserCubit>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal log keluar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log Keluar'),
            ),
          ],
        );
      },
    );
  }
} 