import 'package:flutter/material.dart';

class User extends ChangeNotifier {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? photoUrl;
  bool? emailNotifications;

  User(
      {this.id,
      this.firstName,
      this.lastName,
      this.email,
      this.photoUrl,
      this.emailNotifications});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    photoUrl = json['photoUrl'];
    emailNotifications = json['emailNotifications'];
  }

  void update() {
    notifyListeners();
  }
}
