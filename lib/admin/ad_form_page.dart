import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ad.dart';
import '../theme_constants.dart';

class AdFormPage extends StatefulWidget {
  final Ad? initialAd;
  const AdFormPage({super.key, this.initialAd});

  @override
  State<AdFormPage> createState() => _AdFormPageState();
}

class _AdFormPageState extends State<AdFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  File? _imageFile;
  String? _imagePath;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialAd?.title ?? '');
    _linkController = TextEditingController(text: widget.initialAd?.link ?? '');
    _imagePath = widget.initialAd?.image;
    _deadline = widget.initialAd?.deadline;
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // For gallery, handle both photos and storage for Android
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
          title: const Text('Kebenaran Diperlukan'),
          content: Text(
            source == ImageSource.camera
              ? 'Kebenaran kamera telah ditolak secara kekal. Sila aktifkan dalam tetapan peranti anda.'
              : 'Kebenaran galeri telah ditolak secara kekal. Sila aktifkan dalam tetapan peranti anda.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Buka Tetapan'),
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
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image.')));
      return;
    }
    final ad = Ad(
      title: _titleController.text.trim(),
      link: _linkController.text.trim(),
      image: _imagePath!,
      deadline: _deadline,
    );
    Navigator.of(context).pop(ad);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialAd == null ? 'Add Advertisement' : 'Edit Advertisement'),
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
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Link required' : null,
              ),
              const SizedBox(height: 18),
              Text('Deadline', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _deadline != null
                          ? '${_deadline!.toLocal()}'.split('.').first
                          : 'No deadline selected',
                      style: TextStyle(color: AppColors.secondary, fontSize: 15),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.event),
                    label: const Text('Pick Date/Time'),
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
                        );
                        if (time != null) {
                          setState(() {
                            _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                  ),
                ],
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
                  child: Text(widget.initialAd == null ? 'Add Advertisement' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 