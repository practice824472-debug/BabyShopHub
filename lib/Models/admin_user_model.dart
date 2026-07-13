class AdminUserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final bool isDisabled;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int totalOrders;
  final double totalSpent;

  AdminUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.isDisabled,
    required this.isAdmin,
    required this.createdAt,
    this.lastLogin,
    required this.totalOrders,
    required this.totalSpent,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json, String uid) {
    return AdminUserModel(
      uid: uid,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      isDisabled: json['isDisabled'] ?? false,
      isAdmin: json['role'] == 'admin' || (json['isAdmin'] ?? false),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'isDisabled': isDisabled,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
    };
  }
}
