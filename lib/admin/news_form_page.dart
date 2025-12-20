import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/news.dart';
import '../theme_constants.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/toast_util.dart';

class NewsFormPage extends StatefulWidget {
  final News? initialNews;
  const NewsFormPage({super.key, this.initialNews});

  @override
  State<NewsFormPage> createState() => _NewsFormPageState();
}

class _NewsFormPageState extends State<NewsFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  File? _imageFile;
  String? _imagePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialNews?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialNews?.description ?? '');
    _linkController = TextEditingController(text: widget.initialNews?.link ?? '');
    _imagePath = widget.initialNews?.image;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Request camera permission
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isGranted) return true;
      
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isGranted) return true;
      }
      
      if (cameraStatus.isPermanentlyDenied || await Permission.camera.isPermanentlyDenied) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              'Kebenaran Kamera Diperlukan',
              style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
            ),
            content: Text(
              'Kebenaran kamera telah ditolak. Sila aktifkan dalam tetapan peranti anda untuk mengambil gambar.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Buka Tetapan'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kebenaran kamera diperlukan untuk mengambil gambar.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    } else {
      // Request gallery/photos permission
      Permission permission;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission
        // For older Android, use storage permission
        permission = Permission.photos;
        // Also check storage for older devices
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;
      } else {
        // iOS
        permission = Permission.photos;
      }
      
      var status = await permission.status;
      if (status.isGranted) return true;
      
      if (status.isDenied) {
        status = await permission.request();
        if (status.isGranted) return true;
      }
      
      // For Android, also try storage permission as fallback
      if (Platform.isAndroid && !status.isGranted) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;
        if (storageStatus.isDenied) {
          final storageResult = await Permission.storage.request();
          if (storageResult.isGranted) return true;
        }
      }
      
      if (status.isPermanentlyDenied || await permission.isPermanentlyDenied) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              'Kebenaran Galeri Diperlukan',
              style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
            ),
            content: Text(
              'Kebenaran galeri telah ditolak. Sila aktifkan dalam tetapan peranti anda untuk memilih gambar.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Buka Tetapan'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kebenaran galeri diperlukan untuk memilih gambar.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      try {
        final permanentPath = await _copyImageToPermanentLocation(picked.path);
        setState(() {
          _imageFile = File(permanentPath);
          _imagePath = permanentPath;
        });
      } catch (e) {
        print('Error copying image: $e');
        setState(() {
          _imageFile = File(picked.path);
          _imagePath = picked.path;
        });
      }
    }
  }

  Future<String> _copyImageToPermanentLocation(String tempPath) async {
    final tempFile = File(tempPath);
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}${path.extension(tempPath)}';
    final permanentPath = path.join(imagesDir.path, fileName);
    
    await tempFile.copy(permanentPath);
    
    return permanentPath;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (_imagePath == null) {
      ToastUtil.showError(context, 'Sila pilih gambar.');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    final news = News(
      id: widget.initialNews?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      link: _linkController.text.trim().isEmpty 
          ? null 
          : _linkController.text.trim(),
      image: _imagePath!,
      uploaded: DateTime.now(),
    );
    
    // Use NewsCubit to save the news
    if (widget.initialNews != null) {
      // Update existing news
      context.read<NewsCubit>().updateNews(news);
    } else {
      // Add new news
      context.read<NewsCubit>().addNews(news);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewsCubit, NewsState>(
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.error != null) {
            setState(() {
              _isSubmitting = false;
            });
            ToastUtil.showError(context, 'Ralat: ${state.error}');
          } else if (!state.isLoading && state.error == null) {
            // Success - we just completed a save operation
            setState(() {
              _isSubmitting = false;
            });
            if (widget.initialNews != null) {
              ToastUtil.showSuccess(context, 'Berita berjaya dikemaskini.');
            } else {
              ToastUtil.showSuccess(context, 'Berita berjaya ditambah.');
            }
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialNews == null ? 'Tambah Berita' : 'Edit Berita'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<NewsCubit, NewsState>(
          builder: (context, state) {
            final isLoading = state.isLoading && _isSubmitting;
            return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tajuk',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sila masukkan tajuk';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Penerangan (Pilihan)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Pautan (Pilihan)',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              Text(
                'Gambar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_imageFile != null || (_imagePath != null && File(_imagePath!).existsSync()))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile ?? File(_imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imagePath != null && _imagePath!.startsWith('assets/'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _imagePath!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
          );
          },
        ),
      ),
    );
  }
}

