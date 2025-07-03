class AppUser {
  final String uid;
  final String username;
  final String rol; // 'jefe' o 'colaborador'

  AppUser({
    required this.uid,
    required this.username,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': username,
      'rol': rol,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      username: map['username'],
      rol: map['rol'],
    );
  }
}
