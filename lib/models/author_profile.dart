class AuthorProfile {
  static const defaultName = 'Anonymous';

  final String name;
  final String email;

  const AuthorProfile({this.name = defaultName, this.email = ''});

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  factory AuthorProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final email = json['email'];
    if (name is! String || email is! String) {
      throw const FormatException('Invalid author profile.');
    }
    return AuthorProfile(name: name, email: email);
  }
}
