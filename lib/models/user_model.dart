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
  final Map<String, String>? address; // structured address: {line1, street, postcode, city, state, country}
  final bool hasCompletedBiodata; // tracks if user has filled complete profile
  final String? stripePaymentMethodId; // Stripe payment method ID for saved cards
  final double? latitude; // user's current location latitude
  final double? longitude; // user's current location longitude
  final String? locationName; // formatted location name (e.g., "Kuala Lumpur, Malaysia")
  final Map<String, int>? mushafBookmarks; // {mushafId: pageNumber} - bookmarks for PDF mushafs

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
    this.stripePaymentMethodId,
    this.latitude,
    this.longitude,
    this.locationName,
    this.mushafBookmarks,
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
    Map<String, String>? address,
    bool? hasCompletedBiodata,
    String? stripePaymentMethodId,
    double? latitude,
    double? longitude,
    String? locationName,
    Map<String, int>? mushafBookmarks,
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
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      mushafBookmarks: mushafBookmarks ?? this.mushafBookmarks,
    );
  }

  /// Returns a new UserModel with the classId added to enrolledClassIds if not already present.
  UserModel enrollInClass(String classId) {
    if (enrolledClassIds.contains(classId)) return this;
    return copyWith(enrolledClassIds: [...enrolledClassIds, classId]);
  }

  /// Check if user has completed their biodata profile
  bool get isBiodataComplete {
    if (!hasCompletedBiodata) return false;
    if (name.isEmpty || email.isEmpty) return false;
    if (phone.isEmpty || phone == 'N/A') return false;
    if (birthDate == null) return false;
    if (address == null) return false;
    // Check that all required address fields are present and not empty
    final requiredFields = ['line1', 'street', 'postcode', 'city', 'state', 'country'];
    return requiredFields.every((field) => 
      address![field] != null && address![field]!.trim().isNotEmpty
    );
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
      address: _parseAddress(json['address']),
      hasCompletedBiodata: json['hasCompletedBiodata'] as bool? ?? false,
      stripePaymentMethodId: json['stripePaymentMethodId'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      locationName: json['locationName'] as String?,
      mushafBookmarks: json['mushafBookmarks'] != null
          ? Map<String, int>.from(
              (json['mushafBookmarks'] as Map).map(
                (key, value) => MapEntry(key as String, value as int),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      // userType removed - roles array is the single source of truth
      // userType is kept as computed getter for backward compatibility in code only
      'isPremium': isPremium,
      'profileImage': profileImage,
      'premiumStartDate': premiumStartDate?.toIso8601String(),
      'premiumEndDate': premiumEndDate?.toIso8601String(),
      'enrolledClassIds': enrolledClassIds,
      'roles': roles.map(_userTypeToString).toList(),
      'birthDate': birthDate?.toIso8601String(),
      'address': address, // Firestore will store this as a Map
      'hasCompletedBiodata': hasCompletedBiodata,
      'stripePaymentMethodId': stripePaymentMethodId,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'mushafBookmarks': mushafBookmarks,
    };
  }

  /// Parse address from JSON - handles both old string format and new map format
  static Map<String, String>? _parseAddress(dynamic addressJson) {
    if (addressJson == null) return null;
    
    // New format: Map
    if (addressJson is Map) {
      return Map<String, String>.from(addressJson as Map);
    }
    
    // Old format: Pipe-separated string (backward compatibility)
    if (addressJson is String) {
      final parts = addressJson.split('|');
      if (parts.length >= 6) {
        return {
          'line1': parts[0],
          'street': parts[1],
          'postcode': parts[2],
          'city': parts[3],
          'state': parts[4],
          'country': parts[5],
        };
      }
      // If old format but not pipe-separated, put everything in line1
      if (addressJson.isNotEmpty) {
        return {
          'line1': addressJson,
          'street': '',
          'postcode': '',
          'city': '',
          'state': '',
          'country': '',
        };
      }
    }
    
    return null;
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