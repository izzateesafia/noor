import 'package:flutter/material.dart';
import '../models/video.dart';
import '../theme_constants.dart';

class VideoFormPage extends StatefulWidget {
  final Video? initialVideo;
  const VideoFormPage({super.key, this.initialVideo});

  @override
  State<VideoFormPage> createState() => _VideoFormPageState();
}

class _VideoFormPageState extends State<VideoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _videoUrlController;
  late TextEditingController _categoryController;
  late TextEditingController _durationController;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialVideo?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialVideo?.description ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.initialVideo?.thumbnailUrl ?? '');
    _videoUrlController = TextEditingController(text: widget.initialVideo?.videoUrl ?? '');
    _categoryController = TextEditingController(text: widget.initialVideo?.category ?? '');
    _durationController = TextEditingController(
      text: widget.initialVideo?.duration?.inSeconds.toString() ?? '',
    );
    _isPremium = widget.initialVideo?.isPremium ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailUrlController.dispose();
    _videoUrlController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text);
    final video = Video(
      id: widget.initialVideo?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      thumbnailUrl: _thumbnailUrlController.text.trim(),
      videoUrl: _videoUrlController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      duration: duration != null ? Duration(seconds: duration) : null,
      uploadedAt: widget.initialVideo?.uploadedAt ?? DateTime.now(),
      views: widget.initialVideo?.views ?? 0,
      isPremium: _isPremium,
    );

    Navigator.of(context).pop(video);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialVideo == null ? 'Add Video' : 'Edit Video'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    return 'Please enter a title';
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
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL *',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/thumbnail.jpg',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a thumbnail URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL *',
                  border: OutlineInputBorder(),
                  hintText: 'https://youtube.com/watch?v=... or direct video URL',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a video URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Tafsir, Hadith, Seerah',
                ),
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
                title: const Text('Premium Video'),
                subtitle: const Text('Only premium users can access this video'),
                value: _isPremium,
                onChanged: (value) {
                  setState(() {
                    _isPremium = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




