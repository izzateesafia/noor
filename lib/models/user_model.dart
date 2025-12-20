enum UserType { admin, student, trainer, masterTrainer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone; // new required field
  final bool isPremium;
  final String? profileImage;
  final DateTime? premiumStartDate;
  final DateTime? premiumEndDate;
  final List<String> enrolledClassIds;
  final List<UserType> roles; // multiple roles supported - single source of truth
  final DateTime? birthDate; // new optional field
  final String? address; // new optional field
  final bool hasCompletedBiodata; // tracks if user has filled complete profile

  /// Computed getter: Returns the primary role (first role in roles array)
  /// Falls back to student if roles is empty
  UserType get userType => roles.isNotEmpty ? roles.first : UserType.student;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPremium,
    this.profileImage,
    this.premiumStartDate,
    this.premiumEndDate,
    this.enrolledClassIds = const [],
    this.roles = const [UserType.student],
    this.birthDate,
    this.address,
    this.hasCompletedBiodata = false, // default to false for new users
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isPremium,
    String? profileImage,
    DateTime? premiumStartDate,
    DateTime? premiumEndDate,
    List<String>? enrolledClassIds,
    List<UserType>? roles,
    DateTime? birthDate,
    String? address,
    bool? hasCompletedBiodata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isPremium: isPremium ?? this.isPremium,
      profileImage: profileImage ?? this.profileImage,
      premiumStartDate: premiumStartDate ?? this.premiumStartDate,
      premiumEndDate: premiumEndDate ?? this.premiumEndDate,
      enrolledClassIds: enrolledClassIds ?? this.enrolledClassIds,
      roles: roles ?? this.roles,
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
    // Parse roles - use roles array if available, otherwise fallback to userType for backward compatibility
    final parsedRoles = _parseRoles(json['roles'], json['userType']);
    
    // Ensure roles is never empty (fallback to student)
    final finalRoles = parsedRoles.isNotEmpty 
        ? parsedRoles 
        : [UserType.student];

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      isPremium: json['isPremium'] as bool,
      profileImage: json['profileImage'] as String?,
      premiumStartDate: json['premiumStartDate'] != null ? DateTime.parse(json['premiumStartDate']) : null,
      premiumEndDate: json['premiumEndDate'] != null ? DateTime.parse(json['premiumEndDate']) : null,
      enrolledClassIds: (json['enrolledClassIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      roles: finalRoles,
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
      // Keep userType for backward compatibility (computed from roles)
      'userType': _userTypeToString(userType),
      'isPremium': isPremium,
      'profileImage': profileImage,
      'premiumStartDate': premiumStartDate?.toIso8601String(),
      'premiumEndDate': premiumEndDate?.toIso8601String(),
      'enrolledClassIds': enrolledClassIds,
      'roles': roles.map(_userTypeToString).toList(),
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'hasCompletedBiodata': hasCompletedBiodata,
    };
  }

  static UserType _parseUserType(String? userTypeStr) {
    switch (userTypeStr) {
      case 'admin':
        return UserType.admin;
      case 'trainer':
        return UserType.trainer;
      case 'masterTrainer':
        return UserType.masterTrainer;
      case 'student':
        return UserType.student;
      // Backward compatibility
      case 'nonAdmin':
        return UserType.student;
      default:
        return UserType.student;
    }
  }

  static String _userTypeToString(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'admin';
      case UserType.student:
        return 'student';
      case UserType.trainer:
        return 'trainer';
      case UserType.masterTrainer:
        return 'masterTrainer';
    }
  }

  /// Check if user is a trainer (either trainer or master trainer)
  bool get isTrainer {
    return roles.contains(UserType.trainer) || roles.contains(UserType.masterTrainer);
  }

  bool get canAccessTrainerDash {
    return roles.contains(UserType.trainer) || roles.contains(UserType.masterTrainer);
  }

  bool get canAccessMasterDash {
    return roles.contains(UserType.masterTrainer);
  }

  static List<UserType> _parseRoles(dynamic rolesJson, dynamic userTypeJson) {
    if (rolesJson is List) {
      return rolesJson.map((e) => _parseUserType(e as String?)).toList();
    }
    // backward compatibility: fallback to single userType
    return [_parseUserType(userTypeJson as String?)];
  }
} 