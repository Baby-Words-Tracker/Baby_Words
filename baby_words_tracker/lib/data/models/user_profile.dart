// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/time_utils.dart';
import 'package:collection/collection.dart';

/// User roles in the system
/// Lower index = higher priority/permissions
enum UserRole {
  admin,      // Full system access - web dashboard
  researcher, // Read all data - web only
  parent;     // Manage own children - mobile only
  
  int get priority {
    switch (this) {
      case UserRole.admin:
        return 0;
      case UserRole.researcher:
        return 3;
      case UserRole.parent:
        return 5;
    }
  }
  
  /// Check if this role can access data meant for target role
  bool canAccessData(UserRole targetRole) {
    return priority <= targetRole.priority;
  }
  
  /// Get allowed platforms for this role
  List<String> get allowedPlatforms {
    switch (this) {
      case UserRole.admin:
        return ['web', 'mobile']; // Admins can use both
      case UserRole.researcher:
        return ['web']; // Web only
      case UserRole.parent:
        return ['mobile']; // Mobile only
    }
  }
  
  bool get requiresWebPlatform {
    return this == UserRole.researcher || this == UserRole.admin;
  }
  
  bool get requiresMobilePlatform {
    return this == UserRole.parent;
  }
}

/// User status in the system
enum UserStatus {
  active,    // Normal active user
  demo,      // Demo/sandbox mode - isolated data
  suspended; // Temporarily disabled
}

/// Unified user profile model
/// Replaces Parent, Researcher, and User collections
class UserProfile {
  static String collectionName = 'UserProfile';
  
  final String id;
  final UserRole role;
  final UserStatus status;
  
  // Contact info
  final String? email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? institution; // For researchers
  
  // Auth state
  final bool emailVerified;
  final bool twoFactorEnabled;
  final DateTime? twoFactorEnabledAt;
  
  // Privacy & consent (required for all users)
  final bool acceptedPrivacyPolicy;
  final String? policyVersion;
  final DateTime? consentDate;
  
  // Survey (required for parents only)
  final bool surveyCompleted;
  final String? surveyVersion;
  final DateTime? surveyCompletedAt;
  
  // Parent-specific fields
  final List<String> childIDs;
  final List<String> pendingChildIDs;
  final LanguageCode? preferredLanguage;
  final bool notificationsEnabled;
  final bool nightlyNotificationsEnabled;
  final bool weeklyNotificationsEnabled;
  
  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.role,
    this.status = UserStatus.active,
    this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.institution,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.twoFactorEnabledAt,
    this.acceptedPrivacyPolicy = false,
    this.policyVersion,
    this.consentDate,
    this.surveyCompleted = false,
    this.surveyVersion,
    this.surveyCompletedAt,
    this.childIDs = const [],
    this.pendingChildIDs = const [],
    this.preferredLanguage,
    this.notificationsEnabled = true,
    this.nightlyNotificationsEnabled = true,
    this.weeklyNotificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });
  
  // Helper getters
  bool get isParent => role == UserRole.parent || role == UserRole.admin;
  bool get isResearcher => role == UserRole.researcher;
  bool get isAdmin => role == UserRole.admin;
  bool get isDemoUser => status == UserStatus.demo;
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;

  String get fullName {
    if ((firstName == null || firstName!.isEmpty) &&
        (lastName == null || lastName!.isEmpty)) {
      return name ?? '';
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return (firstName ?? lastName ?? '').trim();
  }
  
  /// Check if user requires survey completion
  bool get requiresSurvey => isParent && !surveyCompleted;
  
  /// Check if user requires 2FA (required for ALL users)
  bool get requires2FA => !twoFactorEnabled;
  
  /// Check if user has 2FA enabled
  bool get has2FAEnabled => twoFactorEnabled;
  
  /// Check if user can access given platform
  bool canAccessPlatform(String platform) {
    return role.allowedPlatforms.contains(platform.toLowerCase());
  }
  
  /// Get collection name based on demo status
  String get effectiveCollectionName {
    return isDemoUser ? 'demo_$collectionName' : collectionName;
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    UserStatus? status,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? institution,
    bool? emailVerified,
    bool? twoFactorEnabled,
    DateTime? twoFactorEnabledAt,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
    bool? surveyCompleted,
    String? surveyVersion,
    DateTime? surveyCompletedAt,
    List<String>? childIDs,
    List<String>? pendingChildIDs,
    LanguageCode? preferredLanguage,
    bool? notificationsEnabled,
    bool? nightlyNotificationsEnabled,
    bool? weeklyNotificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      institution: institution ?? this.institution,
      emailVerified: emailVerified ?? this.emailVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorEnabledAt: twoFactorEnabledAt ?? this.twoFactorEnabledAt,
      acceptedPrivacyPolicy: acceptedPrivacyPolicy ?? this.acceptedPrivacyPolicy,
      policyVersion: policyVersion ?? this.policyVersion,
      consentDate: consentDate ?? this.consentDate,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      surveyVersion: surveyVersion ?? this.surveyVersion,
      surveyCompletedAt: surveyCompletedAt ?? this.surveyCompletedAt,
      childIDs: childIDs ?? this.childIDs,
      pendingChildIDs: pendingChildIDs ?? this.pendingChildIDs,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      nightlyNotificationsEnabled: nightlyNotificationsEnabled ?? this.nightlyNotificationsEnabled,
      weeklyNotificationsEnabled: weeklyNotificationsEnabled ?? this.weeklyNotificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'role': role.name,
      'status': status.name,
      'email': email,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'institution': institution,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorEnabledAt': twoFactorEnabledAt,
      'acceptedPrivacyPolicy': acceptedPrivacyPolicy,
      'policyVersion': policyVersion,
      'consentDate': consentDate,
      'surveyCompleted': surveyCompleted,
      'surveyVersion': surveyVersion,
      'surveyCompletedAt': surveyCompletedAt,
      'childIDs': childIDs,
      'pendingChildIDs': pendingChildIDs,
      'preferredLanguage': preferredLanguage?.name,
      'notificationsEnabled': notificationsEnabled,
      'nightlyNotificationsEnabled': nightlyNotificationsEnabled,
      'weeklyNotificationsEnabled': weeklyNotificationsEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      role: UserRole.values.byName(map['role'] as String? ?? 'parent'),
      status: UserStatus.values.byName(map['status'] as String? ?? 'active'),
      email: map['email'] as String?,
      name: map['name'] as String?,
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      institution: map['institution'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] as bool? ?? false,
      twoFactorEnabledAt: map['twoFactorEnabledAt'] != null
          ? convertToDateTime(map['twoFactorEnabledAt'])
          : null,
      acceptedPrivacyPolicy: map['acceptedPrivacyPolicy'] as bool? ?? false,
      policyVersion: map['policyVersion'] as String?,
      consentDate: map['consentDate'] != null
          ? convertToDateTime(map['consentDate'])
          : null,
      surveyCompleted: map['surveyCompleted'] as bool? ?? false,
      surveyVersion: map['surveyVersion'] as String?,
      surveyCompletedAt: map['surveyCompletedAt'] != null
          ? convertToDateTime(map['surveyCompletedAt'])
          : null,
      childIDs: (map['childIDs'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      pendingChildIDs: (map['pendingChildIDs'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      preferredLanguage: map['preferredLanguage'] != null
          ? LanguageCode.values.byName(map['preferredLanguage'] as String)
          : null,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      nightlyNotificationsEnabled:
          map['nightlyNotificationsEnabled'] as bool? ?? true,
      weeklyNotificationsEnabled:
          map['weeklyNotificationsEnabled'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? convertToDateTime(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? convertToDateTime(map['updatedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  factory UserProfile.fromDataWithId(DataWithId source) {
    Map<String, dynamic> data = source.data;
    data['id'] = source.id;
    return UserProfile.fromMap(data);
  }

  static Map<String, dynamic> createUpdateMap({
    UserRole? role,
    UserStatus? status,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? institution,
    bool? emailVerified,
    bool? twoFactorEnabled,
    DateTime? twoFactorEnabledAt,
    bool? acceptedPrivacyPolicy,
    String? policyVersion,
    DateTime? consentDate,
    bool? surveyCompleted,
    String? surveyVersion,
    DateTime? surveyCompletedAt,
    List<String>? childIDs,
    LanguageCode? preferredLanguage,
    bool? notificationsEnabled,
    bool? nightlyNotificationsEnabled,
    bool? weeklyNotificationsEnabled,
  }) {
    Map<String, dynamic> map = {
      'updatedAt': DateTime.now(),
    };

    if (role != null) map['role'] = role.name;
    if (status != null) map['status'] = status.name;
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (institution != null) map['institution'] = institution;
    if (emailVerified != null) map['emailVerified'] = emailVerified;
    if (twoFactorEnabled != null) map['twoFactorEnabled'] = twoFactorEnabled;
    if (twoFactorEnabledAt != null) {
      map['twoFactorEnabledAt'] = twoFactorEnabledAt;
    }
    if (acceptedPrivacyPolicy != null) {
      map['acceptedPrivacyPolicy'] = acceptedPrivacyPolicy;
    }
    if (policyVersion != null) map['policyVersion'] = policyVersion;
    if (consentDate != null) map['consentDate'] = consentDate;
    if (surveyCompleted != null) map['surveyCompleted'] = surveyCompleted;
    if (surveyVersion != null) map['surveyVersion'] = surveyVersion;
    if (surveyCompletedAt != null) map['surveyCompletedAt'] = surveyCompletedAt;
    if (childIDs != null) map['childIDs'] = childIDs;
    if (preferredLanguage != null) {
      map['preferredLanguage'] = preferredLanguage.name;
    }
    if (notificationsEnabled != null) {
      map['notificationsEnabled'] = notificationsEnabled;
    }
    if (nightlyNotificationsEnabled != null) {
      map['nightlyNotificationsEnabled'] = nightlyNotificationsEnabled;
    }
    if (weeklyNotificationsEnabled != null) {
      map['weeklyNotificationsEnabled'] = weeklyNotificationsEnabled;
    }

    return map;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, role: ${role.name}, status: ${status.name}, email: $email, name: $name, firstName: $firstName, lastName: $lastName, surveyCompleted: $surveyCompleted, childIDs: ${childIDs.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfile) return false;

    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.role == role &&
        other.status == status &&
        other.email == email &&
        other.name == name &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.phoneNumber == phoneNumber &&
        other.institution == institution &&
        other.emailVerified == emailVerified &&
        other.twoFactorEnabled == twoFactorEnabled &&
        other.acceptedPrivacyPolicy == acceptedPrivacyPolicy &&
        other.surveyCompleted == surveyCompleted &&
        listEquals(other.childIDs, childIDs) &&
        listEquals(other.pendingChildIDs, pendingChildIDs);
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        role,
        status,
        email,
        name,
        firstName,
        lastName,
        phoneNumber,
        institution,
        emailVerified,
        twoFactorEnabled,
        acceptedPrivacyPolicy,
        surveyCompleted,
        const DeepCollectionEquality().hash(childIDs),
        const DeepCollectionEquality().hash(pendingChildIDs),
      ]);
}
