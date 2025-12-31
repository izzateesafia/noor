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
    };
  }
} 