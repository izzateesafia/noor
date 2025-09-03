import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme_constants.dart';
import 'dart:io';
import 'manage_hadiths_page.dart';

class HadithFormPage extends StatefulWidget {
  final Hadith? initialHadith;
  const HadithFormPage({super.key, this.initialHadith});

  @override
  State<HadithFormPage> createState() => _HadithFormPageState();
}

class _HadithFormPageState extends State<HadithFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _linkController;
  late TextEditingController _notesController;
  File? _imageFile;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialHadith?.title ?? '');
    _contentController = TextEditingController(text: widget.initialHadith?.content ?? '');
    _linkController = TextEditingController(text: widget.initialHadith?.link ?? '');
    _notesController = TextEditingController(text: widget.initialHadith?.notes ?? '');
    _imagePath = widget.initialHadith?.image;
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      if (Theme.of(context).platform == TargetPlatform.android) {
        permission = Permission.storage;
      } else {
        permission = Permission.photos;
      }
    }
    var status = await permission.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted) return true;
    }
    if (status.isPermanentlyDenied) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            source == ImageSource.camera
              ? 'Camera permission is permanently denied. Please enable it in your device settings.'
              : 'Gallery permission is permanently denied. Please enable it in your device settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          source == ImageSource.camera
            ? 'Camera permission denied.'
            : 'Gallery permission denied.'
        )),
      );
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = picked.path;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final hadith = Hadith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      image: _imagePath,
      link: _linkController.text.trim(),
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop(hadith);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialHadith == null ? 'Add Hadith' : 'Edit Hadith'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
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
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
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
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                  onPressed: _submit,
                  child: Text(widget.initialHadith == null ? 'Add Hadith' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 