class User {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String role;
  final String photoUrl;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    required this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      displayName: json['display_name'],
      phoneNumber: json['phone_number'],
      role: json['cargo'],
      photoUrl: json['photo_url'] ?? '',
    );
  }
}
