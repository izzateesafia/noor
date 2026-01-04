// ClassModel: Data model for Class entity, used for backend integration
class ClassModel {
  final String id;
  final String title;
  final String instructor;
  final String time;
  final String duration;
  final String level;
  final String description;
  final String? image;
  final double price;
  final String? paymentUrl;
  final bool isHidden;

  ClassModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.time,
    required this.duration,
    required this.level,
    required this.description,
    this.image,
    required this.price,
    this.paymentUrl,
    this.isHidden = false,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      title: json['title'] as String,
      instructor: json['instructor'] as String,
      time: json['time'] as String,
      duration: json['duration'] as String,
      level: json['level'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
      price: (json['price'] as num).toDouble(),
      paymentUrl: json['paymentUrl'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructor': instructor,
      'time': time,
      'duration': duration,
      'level': level,
      'description': description,
      'image': image,
      'price': price,
      'paymentUrl': paymentUrl,
      'isHidden': isHidden,
    };
  }

  ClassModel copyWith({
    String? id,
    String? title,
    String? instructor,
    String? time,
    String? duration,
    String? level,
    String? description,
    String? image,
    double? price,
    String? paymentUrl,
    bool? isHidden,
  }) {
    return ClassModel(
      id: id ?? this.id,
      title: title ?? this.title,
      instructor: instructor ?? this.instructor,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      isHidden: isHidden ?? this.isHidden,
    );
  }
} 