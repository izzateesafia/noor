class DailyTrackerData {
  final String id;
  final String userId;
  final Map<String, bool> prayersCompleted;
  final bool quranRecited;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyTrackerData({
    required this.id,
    required this.userId,
    required this.prayersCompleted,
    required this.quranRecited,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyTrackerData.fromJson(Map<String, dynamic> json) {
    return DailyTrackerData(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      prayersCompleted: Map<String, bool>.from(json['prayersCompleted'] ?? {}),
      quranRecited: json['quranRecited'] ?? false,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'prayersCompleted': prayersCompleted,
      'quranRecited': quranRecited,
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DailyTrackerData copyWith({
    String? id,
    String? userId,
    Map<String, bool>? prayersCompleted,
    bool? quranRecited,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTrackerData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prayersCompleted: prayersCompleted ?? this.prayersCompleted,
      quranRecited: quranRecited ?? this.quranRecited,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
