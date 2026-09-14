class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String university;
  final String degree;
  final int currentSemester;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.university,
    required this.degree,
    required this.currentSemester,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      university: json['university'] as String? ?? 'University',
      degree: json['degree'] as String? ?? 'General Degree',
      currentSemester: (json['current_semester'] as num?)?.toInt() ?? 1,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'university': university,
      'degree': degree,
      'current_semester': currentSemester,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? university,
    String? degree,
    int? currentSemester,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      currentSemester: currentSemester ?? this.currentSemester,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
