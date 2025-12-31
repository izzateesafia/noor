import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/news.dart';
import '../theme_constants.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/toast_util.dart';
import '../utils/photo_permission_helper.dart';
import '../services/image_upload_service.dart';

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
  final ImageUploadService _imageUploadService = ImageUploadService();

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
    return await PhotoPermissionHelper.checkAndRequestPhotoPermission(
      context,
      source: source,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = null; // Clear old path when new image is selected
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    
    if (_imageFile == null && (_imagePath == null || _imagePath!.isEmpty)) {
      ToastUtil.showError(context, 'Sila pilih gambar.');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      String? imageUrl = widget.initialNews?.image;
      
      // Upload new image if selected
      if (_imageFile != null) {
        imageUrl = await _imageUploadService.uploadNewsImage(
          _imageFile!,
          existingUrl: widget.initialNews?.image,
        );
      }
      
      final news = News(
        id: widget.initialNews?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        link: _linkController.text.trim().isEmpty 
            ? null 
            : _linkController.text.trim(),
        image: imageUrl!,
        uploaded: DateTime.now(),
      );
      
      // Use NewsCubit to save the news
      if (widget.initialNews != null) {
        context.read<NewsCubit>().updateNews(news);
      } else {
        context.read<NewsCubit>().addNews(news);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ToastUtil.showError(context, 'Ralat memuat naik gambar: $e');
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
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imagePath != null && _imagePath!.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagePath!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        child: const Icon(Icons.error),
                      );
                    },
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

