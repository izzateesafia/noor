import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '../models/video.dart';
import '../models/video_category.dart';
import '../theme_constants.dart';
import '../cubit/video_cubit.dart';
import '../cubit/video_states.dart';
import '../repository/video_repository.dart';
import '../services/image_upload_service.dart';
import '../utils/photo_permission_helper.dart';

class VideoFormPage extends StatefulWidget {
  final Video? initialVideo;
  const VideoFormPage({super.key, this.initialVideo});

  @override
  State<VideoFormPage> createState() => _VideoFormPageState();
}

class _VideoFormPageState extends State<VideoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _uploadService = ImageUploadService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _videoUrlController;
  late TextEditingController _categoryController;
  late TextEditingController _durationController;
  late TextEditingController _customCategoryController;
  bool _isPremium = false;
  VideoCategory? _selectedCategoryEnum;
  bool _isCustomCategory = false;
  bool _useThumbnailUrl = true;
  bool _useVideoUrl = true;
  File? _thumbnailFile;
  File? _videoFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialVideo?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialVideo?.description ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.initialVideo?.thumbnailUrl ?? '');
    _videoUrlController = TextEditingController(text: widget.initialVideo?.videoUrl ?? '');
    _categoryController = TextEditingController(text: widget.initialVideo?.category ?? '');
    _customCategoryController = TextEditingController();
    _durationController = TextEditingController(
      text: widget.initialVideo?.duration?.inSeconds.toString() ?? '',
    );
    _isPremium = widget.initialVideo?.isPremium ?? false;
    
    // Initialize category selection
    final initialCategory = widget.initialVideo?.category;
    if (initialCategory != null && initialCategory.isNotEmpty) {
      final categoryEnum = VideoCategory.fromString(initialCategory);
      if (categoryEnum != null) {
        _selectedCategoryEnum = categoryEnum;
        _isCustomCategory = false;
      } else {
        _selectedCategoryEnum = null;
        _isCustomCategory = true;
        _customCategoryController.text = initialCategory;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailUrlController.dispose();
    _videoUrlController.dispose();
    _categoryController.dispose();
    _customCategoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    return await PhotoPermissionHelper.checkAndRequestPhotoPermission(
      context,
      source: source,
    );
  }

  Future<void> _pickThumbnail(ImageSource source) async {
    // Check and request permission first
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _thumbnailFile = File(picked.path);
        _useThumbnailUrl = false;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    // Check and request permission first
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: source);
    if (picked != null) {
      final filePath = picked.path;
      final extension = path.extension(filePath).toLowerCase();
      
      // Allowed video formats: .mov, .mp4, .m4v
      const allowedExtensions = ['.mov', '.mp4', '.m4v'];
      
      // Validate file format
      if (!allowedExtensions.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Format fail tidak disokong. Sila pilih fail video dalam format MP4, MOV, atau M4V sahaja.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      setState(() {
        _videoFile = File(filePath);
        _useVideoUrl = false;
      });
    }
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String thumbnailUrl = _thumbnailUrlController.text.trim();
      String videoUrl = _videoUrlController.text.trim();

      // Upload thumbnail if file is selected
      if (!_useThumbnailUrl && _thumbnailFile != null) {
        thumbnailUrl = await _uploadService.uploadVideoThumbnail(
          _thumbnailFile!,
          existingUrl: widget.initialVideo?.thumbnailUrl,
        );
      }

      // Upload video if file is selected
      if (!_useVideoUrl && _videoFile != null) {
        videoUrl = await _uploadService.uploadVideo(
          _videoFile!,
          existingUrl: widget.initialVideo?.videoUrl,
        );
      }

      // Validate URLs if using URL mode
      if (_useThumbnailUrl && thumbnailUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila masukkan URL gambar kecil atau muat naik gambar')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      if (_useVideoUrl && videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila masukkan URL video atau muat naik fail video')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Determine category value
      String? categoryValue;
      if (_isCustomCategory && _customCategoryController.text.trim().isNotEmpty) {
        categoryValue = _customCategoryController.text.trim();
      } else if (_selectedCategoryEnum != null) {
        categoryValue = _selectedCategoryEnum!.displayName;
      }

      final duration = int.tryParse(_durationController.text);
      final video = Video(
        id: widget.initialVideo?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        category: categoryValue,
        duration: duration != null ? Duration(seconds: duration) : null,
        uploadedAt: widget.initialVideo?.uploadedAt ?? DateTime.now(),
        views: widget.initialVideo?.views ?? 0,
        isPremium: _isPremium,
        isHidden: widget.initialVideo?.isHidden ?? false,
        isFeatured: widget.initialVideo?.isFeatured ?? false,
        isPopular: widget.initialVideo?.isPopular ?? false,
        isForYou: widget.initialVideo?.isForYou ?? false,
      );

      if (mounted) {
        Navigator.of(context).pop(video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menyimpan video: $e')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Try to get existing VideoCubit, otherwise create new one
    VideoCubit videoCubit;
    try {
      videoCubit = context.read<VideoCubit>();
      // Ensure categories are fetched
      videoCubit.fetchCategories();
    } catch (e) {
      videoCubit = VideoCubit(VideoRepository())..fetchCategories();
    }
    
    return BlocProvider.value(
      value: videoCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialVideo == null ? 'Add Video' : 'Edit Video'),
          backgroundColor: AppColors.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
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
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Thumbnail Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Thumbnail *',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          ToggleButtons(
                            isSelected: [_useThumbnailUrl, !_useThumbnailUrl],
                            onPressed: (index) {
                              setState(() {
                                _useThumbnailUrl = index == 0;
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('URL'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: const Text('Muat Naik'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_useThumbnailUrl)
                        TextFormField(
                          controller: _thumbnailUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Thumbnail URL',
                            border: OutlineInputBorder(),
                            hintText: 'https://example.com/thumbnail.jpg',
                          ),
                          validator: (value) {
                            if (_useThumbnailUrl && (value == null || value.trim().isEmpty)) {
                              return 'Sila masukkan URL gambar kecil';
                            }
                            return null;
                          },
                        )
                      else ...[
                        if (_thumbnailFile != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _thumbnailFile!.path.split('/').last,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _thumbnailFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickThumbnail(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeri'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _pickThumbnail(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Video Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Video *',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          ToggleButtons(
                            isSelected: [_useVideoUrl, !_useVideoUrl],
                            onPressed: (index) {
                              setState(() {
                                _useVideoUrl = index == 0;
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('URL'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: const Text('Muat Naik'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Video format information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Format Video yang Disokong',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Format: MP4 / MOV / M4V\nSaiz maksimum: 500MB\n\nUntuk memastikan video boleh dimainkan dengan baik pada semua peranti, terutamanya iOS, sila gunakan format MP4 dengan codec H.264 atau H.265.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse('https://www.freeconvert.com/video-converter');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.link, size: 16),
                              label: const Text('Tukar format video (Pembekal percuma)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_useVideoUrl)
                        TextFormField(
                          controller: _videoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Video URL',
                            border: OutlineInputBorder(),
                            hintText: 'https://youtube.com/watch?v=... or direct video URL',
                          ),
                          validator: (value) {
                            if (_useVideoUrl && (value == null || value.trim().isEmpty)) {
                              return 'Sila masukkan URL video';
                            }
                            return null;
                          },
                        )
                      else ...[
                        if (_videoFile != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _videoFile!.path.split('/').last,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _videoFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickVideo(ImageSource.gallery),
                              icon: const Icon(Icons.video_library),
                              label: const Text('Galeri'),
                            ),
                            const SizedBox(width: 12),
                        ElevatedButton.icon(
                              onPressed: () => _pickVideo(ImageSource.camera),
                              icon: const Icon(Icons.videocam),
                              label: const Text('Kamera'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _isCustomCategory 
                        ? '__CUSTOM__' 
                        : (_selectedCategoryEnum?.displayName ?? null),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: const Text('Tiada'),
                      ),
                      ...VideoCategory.predefinedCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.displayName,
                          child: Text(category.displayName),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: '__CUSTOM__',
                        child: const Text('Kustom'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value == null) {
                          _selectedCategoryEnum = null;
                          _isCustomCategory = false;
                          _customCategoryController.clear();
                        } else if (value == '__CUSTOM__') {
                          _selectedCategoryEnum = null;
                          _isCustomCategory = true;
                        } else {
                          _selectedCategoryEnum = VideoCategory.fromString(value);
                          _isCustomCategory = false;
                          _customCategoryController.clear();
                        }
                      });
                    },
                  ),
                  if (_isCustomCategory) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori Kustom',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan kategori kustom',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 3600 for 1 hour',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Video Premium'),
                subtitle: const Text('Hanya pengguna premium boleh mengakses video ini'),
                value: _isPremium,
                onChanged: (value) {
                  setState(() {
                    _isPremium = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ?  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          const Text('Memuat naik...'),
                        ],
                      )
                    : const Text('Simpan Video'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}




