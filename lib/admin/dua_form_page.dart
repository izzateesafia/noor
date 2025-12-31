import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dua.dart';
import '../theme_constants.dart';
import '../utils/photo_permission_helper.dart';
import '../services/image_upload_service.dart';
import 'dart:io';
import 'manage_duas_page.dart';

class DuaFormPage extends StatefulWidget {
  final Dua? initialDua;
  const DuaFormPage({super.key, this.initialDua});

  @override
  State<DuaFormPage> createState() => _DuaFormPageState();
}

class _DuaFormPageState extends State<DuaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _linkController;
  late TextEditingController _notesController;
  File? _imageFile;
  String? _imagePath;
  bool _isUploading = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialDua?.title ?? '');
    _contentController = TextEditingController(text: widget.initialDua?.content ?? '');
    _linkController = TextEditingController(text: widget.initialDua?.link ?? '');
    _notesController = TextEditingController(text: widget.initialDua?.notes ?? '');
    _imagePath = widget.initialDua?.image;
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
    
    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = widget.initialDua?.image;
      
      // Upload new image if selected
      if (_imageFile != null) {
        imageUrl = await _imageUploadService.uploadDuaImage(
          _imageFile!,
          existingUrl: widget.initialDua?.image,
        );
      }
      
      final isEdit = widget.initialDua != null;
      final dua = Dua(
        id: isEdit ? widget.initialDua!.id : '', // empty string for new, repo will assign
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        image: imageUrl,
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        uploaded: isEdit ? widget.initialDua!.uploaded : DateTime.now(),
      );
      
      if (mounted) {
        Navigator.of(context).pop(dua);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialDua == null ? 'Add Dua' : 'Edit Dua'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 60,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title required';
                  if (v.trim().length > 60) return 'Max 60 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Content required';
                  if (v.trim().length > 500) return 'Max 500 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 200,
                validator: (v) {
                  if (v != null && v.trim().length > 200) return 'Max 200 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLines: 2,
                maxLength: 200,
                validator: (v) {
                  if (v != null && v.trim().length > 200) return 'Max 200 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text('Image', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imagePath != null && _imagePath!.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagePath!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[300],
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
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isUploading ? null : _submit,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.initialDua == null ? 'Add Dua' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 