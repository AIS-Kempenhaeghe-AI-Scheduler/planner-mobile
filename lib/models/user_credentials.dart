class UserCredentials {
  final String username;
  final String pincode;

  UserCredentials({
    required this.username,
    required this.pincode,
  });

  factory UserCredentials.fromJson(Map<String, dynamic> json) {
    return UserCredentials(
      username: json['username'],
      pincode: json['pincode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'pincode': pincode,
    };
  }
}
