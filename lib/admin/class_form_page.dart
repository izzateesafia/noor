import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/class_model.dart';
import '../theme_constants.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../services/image_upload_service.dart';
import '../utils/photo_permission_helper.dart';
import 'manage_classes_page.dart';

class ClassFormPage extends StatefulWidget {
  final ClassModel? initialClass;
  final void Function(ClassModel)? onSave;
  const ClassFormPage({super.key, this.initialClass, this.onSave});

  @override
  State<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends State<ClassFormPage> {
  late TextEditingController titleController;
  late TextEditingController instructorController;
  late TextEditingController priceController;
  late TextEditingController levelController;
  late TextEditingController descriptionController;
  late TextEditingController imageController;
  late TextEditingController paymentUrlController;

  // Enhanced fields
  TimeOfDay? selectedTime;
  int durationMinutes = 60;
  List<String> selectedDays = [];
  final List<String> allDays = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
  final List<String> levelChoices = ['Pemula', 'Pertengahan', 'Lanjutan', 'Semua Tahap'];
  String? selectedLevel;
  bool isSubmitting = false;

  // Image picker fields
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();
  String? _uploadedImageUrl; // Store the Firebase Storage URL
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialClass;
    titleController = TextEditingController(text: c?.title ?? '');
    instructorController = TextEditingController(text: c?.instructor ?? '');
    priceController = TextEditingController(text: c?.price.toString() ?? '');
    levelController = TextEditingController(text: c?.level ?? '');
    descriptionController = TextEditingController(text: c?.description ?? '');
    imageController = TextEditingController(text: c?.image ?? '');
    paymentUrlController = TextEditingController(text: c?.paymentUrl ?? '');
    // Parse time and days from initialClass
    if (c != null && c.time.isNotEmpty) {
      // First, extract days by finding day names in the string
      selectedDays = allDays.where((d) => c.time.contains(d)).toList();
      
      // Remove days from the string to get the time portion
      String timePortion = c.time;
      for (final day in allDays) {
        timePortion = timePortion.replaceAll(day, '');
      }
      // Remove separators and clean up
      timePortion = timePortion.replaceAll('|', '').replaceAll(',', '').trim();
      
      // Parse time from the remaining string
      if (timePortion.isNotEmpty && timePortion.contains(':')) {
        // Handle 24-hour format (HH:MM) or 12-hour format (H:MM AM/PM)
        final timePattern = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false);
        final match = timePattern.firstMatch(timePortion);
        
        if (match != null) {
          int hour = int.tryParse(match.group(1) ?? '') ?? 0;
          int minute = int.tryParse(match.group(2) ?? '') ?? 0;
          final period = match.group(3)?.toUpperCase();
          
          // Convert 12-hour to 24-hour format if needed
          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }
          
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        } else {
          // Fallback: try simple HH:MM format
          final parts = timePortion.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0].trim()) ?? 0;
            final minute = int.tryParse(parts[1].trim().split(' ')[0]) ?? 0;
            selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
      // Parse duration (e.g., '60 min')
      final dur = int.tryParse(c.duration.replaceAll(RegExp(r'[^0-9]'), ''));
      if (dur != null) durationMinutes = dur;
      // Set selectedLevel
      if (levelChoices.contains(c.level)) {
        selectedLevel = c.level;
      } else {
        selectedLevel = levelChoices.first;
      }
      // Set uploaded image URL if it's a Firebase Storage URL
      if (c.image != null && c.image!.isNotEmpty) {
        if (c.image!.startsWith('http://') || c.image!.startsWith('https://')) {
          _uploadedImageUrl = c.image;
        } else {
          // Old local path, keep it for backward compatibility
          imageController.text = c.image!;
        }
      }
    } else {
      selectedLevel = levelChoices.first;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    instructorController.dispose();
    priceController.dispose();
    levelController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    paymentUrlController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
              primary: AppColors.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _pickDuration() async {
    int temp = durationMinutes;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duration (minutes)'),
        content: SizedBox(
          height: 120,
          child: StatefulBuilder(
            builder: (context, setStateDialog) => Column(
              children: [
                Expanded(
                  child: Slider(
                    min: 15,
                    max: 180,
                    divisions: 33,
                    value: temp.toDouble(),
                    label: '$temp min',
                    onChanged: (v) {
                      setStateDialog(() {
                        temp = v.round();
                      });
                    },
                  ),
                ),
                Text('$temp minutes'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                durationMinutes = temp;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    return await PhotoPermissionHelper.checkAndRequestPhotoPermission(
      context,
      source: source,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Check and request permission first
    final hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) return;

    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      setState(() {
        _pickedImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final existingUrl = widget.initialClass?.image;
      final imageUrl = await _imageUploadService.uploadClassThumbnail(
        _pickedImage!,
        existingUrl: existingUrl,
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
        imageController.text = imageUrl; // Store the Firebase Storage URL
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _save() async {
    // Validate required fields
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a class title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (instructorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an instructor name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Format time consistently using 24-hour format
    final timeStr = selectedTime != null 
        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';
    
    // Format days with proper spacing
    final daysStr = selectedDays.join(', ');
    
    // Combine days and time with a clear separator
    String timeField;
    if (daysStr.isNotEmpty && timeStr.isNotEmpty) {
      timeField = '$daysStr | $timeStr';
    } else if (daysStr.isNotEmpty) {
      timeField = daysStr;
    } else if (timeStr.isNotEmpty) {
      timeField = timeStr;
    } else {
      timeField = '';
    }
    // Use uploaded Firebase Storage URL if available, otherwise use the controller value
    final imageUrl = _uploadedImageUrl ?? imageController.text.trim();
    
    final newClass = ClassModel(
      id: widget.initialClass?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      instructor: instructorController.text.trim(),
      price: double.tryParse(priceController.text) ?? 0.0,
      time: timeField,
      duration: '$durationMinutes min',
      level: selectedLevel ?? levelController.text,
      description: descriptionController.text.trim(),
      image: imageUrl.isNotEmpty ? imageUrl : null,
      paymentUrl: paymentUrlController.text.trim().isEmpty ? null : paymentUrlController.text.trim(),
    );
    
    if (widget.initialClass == null) {
      // Adding new class
      setState(() { isSubmitting = true; });
      context.read<ClassCubit>().addClass(newClass);
    } else {
      // Editing existing class
      setState(() { isSubmitting = true; });
      context.read<ClassCubit>().updateClass(newClass);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialClass != null;
    return BlocListener<ClassCubit, ClassState>(
      listener: (context, state) async {
        if (isSubmitting) {
          if (state.status == ClassStatus.loaded) {
            setState(() { isSubmitting = false; });
            final isEdit = widget.initialClass != null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit 
                  ? 'Class successfully updated!' 
                  : 'Class successfully added!'),
                backgroundColor: Colors.green,
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            context.read<ClassCubit>().fetchClasses();
            Navigator.of(context).pop();
          } else if (state.status == ClassStatus.error) {
            setState(() { isSubmitting = false; });
            final isEdit = widget.initialClass != null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit
                  ? 'Failed to update class: ${state.error ?? 'Unknown error'}'
                  : 'Failed to add class: ${state.error ?? 'Unknown error'}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: isSubmitting,
            child: Scaffold(
              appBar: AppBar(
                title: Text(isEdit ? 'Edit Class' : 'Add Class'),
                backgroundColor: AppColors.appBar,
                foregroundColor: AppColors.onAppBar,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[100] 
                            : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.black87 
                              : Colors.white70,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: instructorController,
                      decoration: InputDecoration(
                        labelText: 'Instructor',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[100] 
                            : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.black87 
                              : Colors.white70,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[100] 
                            : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.black87 
                              : Colors.white70,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    // Day picker
                    Text('Days', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8,
                      children: allDays.map((day) => FilterChip(
                        label: Text(
                          day,
                          style: TextStyle(
                            color: selectedDays.contains(day)
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.light 
                                    ? Colors.black 
                                    : Colors.white),
                          ),
                        ),
                        selected: selectedDays.contains(day),
                        selectedColor: AppColors.primary,
                        backgroundColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[200] 
                            : Colors.grey[700],
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[400]! 
                              : Colors.grey[600]!,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 14),
                    // Time picker
                    Row(
                      children: [
                        Text('Time', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _pickTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(selectedTime != null ? selectedTime!.format(context) : 'Pick Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Duration picker
                    Row(
                      children: [
                        Text('Duration', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _pickDuration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('$durationMinutes min'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Level dropdown
                    Row(
                      children: [
                        Text('Level', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.grey[100] 
                                : Colors.grey[800],
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.light 
                                  ? Colors.black 
                                  : Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: selectedLevel,
                            underline: Container(), // Remove default underline
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).brightness == Brightness.light 
                                  ? Colors.black 
                                  : Colors.white,
                            ),
                            dropdownColor: Theme.of(context).brightness == Brightness.light 
                                ? Colors.grey[100] 
                                : Colors.grey[800],
                            items: levelChoices.map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.light 
                                      ? Colors.black 
                                      : Colors.white,
                                ),
                              ),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedLevel = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[100] 
                            : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.black87 
                              : Colors.white70,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: paymentUrlController,
                      decoration: InputDecoration(
                        labelText: 'Payment URL',
                        hintText: 'https://example.com/payment',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey[100] 
                            : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black 
                                : Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.black87 
                              : Colors.white70,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.black 
                            : Colors.white,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    Text('Class Image', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isUploadingImage)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_pickedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _uploadedImageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.broken_image),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      )
                    else if (imageController.text.isNotEmpty && 
                             !imageController.text.startsWith('http'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imageController.text),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        child: Text(isEdit ? 'Save Changes' : 'Add Class'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 