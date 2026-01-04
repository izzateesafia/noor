import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ad.dart';
import '../services/image_upload_service.dart';
import '../utils/photo_permission_helper.dart';

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
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  File? _imageFile;
  String? _imagePath;
  DateTime? _deadline;
  bool _isUploading = false;
  bool _isActive = true;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialAd?.title ?? '');
    _linkController = TextEditingController(text: widget.initialAd?.link ?? '');
    _descriptionController = TextEditingController(text: widget.initialAd?.description ?? '');
    _notesController = TextEditingController(text: widget.initialAd?.notes ?? '');
    _imagePath = widget.initialAd?.image;
    _deadline = widget.initialAd?.deadline;
    _isActive = widget.initialAd?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
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
    if (_imageFile == null && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sila pilih gambar.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = widget.initialAd?.image;
      
      // Upload new image if selected
      if (_imageFile != null) {
        imageUrl = await _imageUploadService.uploadAdImage(
          _imageFile!,
          existingUrl: widget.initialAd?.image,
        );
      }
      
      final ad = Ad(
        id: widget.initialAd?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        image: imageUrl,
        deadline: _deadline,
        uploaded: widget.initialAd?.uploaded ?? DateTime.now(),
        createdAt: widget.initialAd?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
      );
      
      if (mounted) {
        Navigator.of(context).pop(ad);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat memuat naik gambar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imageFile!,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imagePath != null) {
      if (_imagePath!.startsWith('http://') || _imagePath!.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _imagePath!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 140,
                width: double.infinity,
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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              );
            },
          ),
        );
      } else if (_imagePath!.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            _imagePath!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      } else if (File(_imagePath!).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialAd == null ? 'Tambah Iklan' : 'Edit Iklan'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tajuk',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Tajuk diperlukan' : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Penerangan',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: 'Pautan',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: 'https://example.com',
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Nota',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tarikh Tamat',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _deadline != null
                                ? '${_deadline!.toLocal()}'.split('.').first
                                : 'Tiada tarikh tamat dipilih',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          icon: const Icon(Icons.event),
                          label: const Text('Pilih Tarikh/Masa'),
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
                    Text(
                      'Gambar',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
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
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildImagePreview(),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      subtitle: const Text('Paparkan iklan kepada pengguna'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isUploading ? null : _submit,
                        child: Text(widget.initialAd == null ? 'Tambah Iklan' : 'Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 