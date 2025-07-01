class AppUser {
  final String uid;
  final String name;
  final String email;
  final String rol; // 'jefe' o 'colaborador'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'rol': rol,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      rol: map['rol'],
    );
  }
}
