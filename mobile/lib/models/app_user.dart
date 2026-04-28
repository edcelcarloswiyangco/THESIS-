class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.isAdmin,
  });

  final int id;
  final String fullName;
  final String email;
  final String contactNumber;
  final String address;
  final bool isAdmin;

  String get name => fullName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: (json['full_name'] ?? json['name']) as String,
      email: json['email'] as String,
      contactNumber: (json['contact_number'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      isAdmin: json['is_admin'] == true,
    );
  }
}
