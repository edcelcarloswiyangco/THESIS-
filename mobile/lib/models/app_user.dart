class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      isAdmin: json['is_admin'] == true,
    );
  }
}
