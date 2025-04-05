class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? imageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      imageUrl: map['imageUrl'],
    );
  }


}
