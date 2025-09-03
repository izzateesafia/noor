import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/class_model.dart';
import '../theme_constants.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
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

  // Enhanced fields
  TimeOfDay? selectedTime;
  int durationMinutes = 60;
  List<String> selectedDays = [];
  final List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> levelChoices = ['Beginner', 'Intermediate', 'Advanced', 'All Levels'];
  String? selectedLevel;
  bool isSubmitting = false;

  // Image picker fields
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = widget.initialClass;
    titleController = TextEditingController(text: c?.title ?? '');
    instructorController = TextEditingController(text: c?.instructor ?? '');
    priceController = TextEditingController(text: c?.price.toString() ?? '0.0');
    levelController = TextEditingController(text: c?.level ?? '');
    descriptionController = TextEditingController(text: c?.description ?? '');
    imageController = TextEditingController(text: c?.image ?? '');
    // Parse time and days from initialClass
    if (c != null) {
      // Parse time (e.g., '14:00')
      if (c.time.isNotEmpty && c.time.contains(':')) {
        final parts = c.time.split(':');
        selectedTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 14, minute: int.tryParse(parts[1]) ?? 0);
      }
      // Parse days (e.g., 'Mon,Wed')
      selectedDays = allDays.where((d) => c.time.contains(d)).toList();
      // Parse duration (e.g., '60 min')
      final dur = int.tryParse(c.duration.replaceAll(RegExp(r'[^0-9]'), ''));
      if (dur != null) durationMinutes = dur;
      // Set selectedLevel
      if (levelChoices.contains(c.level)) {
        selectedLevel = c.level;
      } else {
        selectedLevel = levelChoices.first;
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
              onPrimary: Colors.white,
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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        imageController.text = pickedFile.path;
      });
    }
  }

  void _save() async {
    final timeStr = selectedTime != null ? selectedTime!.format(context) : '';
    final daysStr = selectedDays.join(',');
    final timeField = daysStr.isNotEmpty ? '$daysStr $timeStr' : timeStr;
    final newClass = ClassModel(
      id: widget.initialClass?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text,
      instructor: instructorController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
      time: timeField,
      duration: '$durationMinutes min',
      level: selectedLevel ?? levelController.text,
      description: descriptionController.text,
      image: imageController.text,
    );
    if (widget.initialClass == null) {
      setState(() { isSubmitting = true; });
      context.read<ClassCubit>().addClass(newClass);
    } else {
      widget.onSave?.call(newClass);
      Navigator.of(context).pop();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Class successfully added!')),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            context.read<ClassCubit>().fetchClasses();
            Navigator.of(context).pop();
          } else if (state.status == ClassStatus.error) {
            setState(() { isSubmitting = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add class: ${state.error ?? 'Unknown error'}')),
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
                    if (_pickedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (imageController.text.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imageController.text),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
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