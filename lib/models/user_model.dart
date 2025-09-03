enum UserType { admin, nonAdmin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone; // new required field
  final UserType userType;
  final bool isPremium;
  final String? profileImage;
  final DateTime? premiumStartDate;
  final DateTime? premiumEndDate;
  final List<String> enrolledClassIds;
  final DateTime? birthDate; // new optional field
  final String? address; // new optional field
  final bool hasCompletedBiodata; // tracks if user has filled complete profile

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.isPremium,
    this.profileImage,
    this.premiumStartDate,
    this.premiumEndDate,
    this.enrolledClassIds = const [],
    this.birthDate,
    this.address,
    this.hasCompletedBiodata = false, // default to false for new users
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    bool? isPremium,
    String? profileImage,
    DateTime? premiumStartDate,
    DateTime? premiumEndDate,
    List<String>? enrolledClassIds,
    DateTime? birthDate,
    String? address,
    bool? hasCompletedBiodata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      isPremium: isPremium ?? this.isPremium,
      profileImage: profileImage ?? this.profileImage,
      premiumStartDate: premiumStartDate ?? this.premiumStartDate,
      premiumEndDate: premiumEndDate ?? this.premiumEndDate,
      enrolledClassIds: enrolledClassIds ?? this.enrolledClassIds,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      hasCompletedBiodata: hasCompletedBiodata ?? this.hasCompletedBiodata,
    );
  }

  /// Returns a new UserModel with the classId added to enrolledClassIds if not already present.
  UserModel enrollInClass(String classId) {
    if (enrolledClassIds.contains(classId)) return this;
    return copyWith(enrolledClassIds: [...enrolledClassIds, classId]);
  }

  /// Check if user has completed their biodata profile
  bool get isBiodataComplete {
    return hasCompletedBiodata && 
           name.isNotEmpty && 
           email.isNotEmpty && 
           phone.isNotEmpty &&
           phone != 'N/A' &&
           birthDate != null &&
           address != null &&
           address!.isNotEmpty;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      userType: json['userType'] == 'admin' ? UserType.admin : UserType.nonAdmin,
      isPremium: json['isPremium'] as bool,
      profileImage: json['profileImage'] as String?,
      premiumStartDate: json['premiumStartDate'] != null ? DateTime.parse(json['premiumStartDate']) : null,
      premiumEndDate: json['premiumEndDate'] != null ? DateTime.parse(json['premiumEndDate']) : null,
      enrolledClassIds: (json['enrolledClassIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      address: json['address'] as String?,
      hasCompletedBiodata: json['hasCompletedBiodata'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType == UserType.admin ? 'admin' : 'nonAdmin',
      'isPremium': isPremium,
      'profileImage': profileImage,
      'premiumStartDate': premiumStartDate?.toIso8601String(),
      'premiumEndDate': premiumEndDate?.toIso8601String(),
      'enrolledClassIds': enrolledClassIds,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'hasCompletedBiodata': hasCompletedBiodata,
    };
  }
} 