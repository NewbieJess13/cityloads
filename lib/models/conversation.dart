import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation extends ChangeNotifier {
  String? id;
  String? userId;
  String? userFullName;
  String? userPhotoUrl;
  String? lastMessageId;
  String? lastMessage;
  String? lastMessageTimestamp;
  bool? lastMessageIsRead;
  DocumentSnapshot? documentSnapshot;

  Conversation({
    this.id,
    this.userId,
    this.userFullName,
    this.userPhotoUrl,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.lastMessageIsRead,
    this.documentSnapshot,
  });

  Conversation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userFullName = json['userFullName'];
    userPhotoUrl = json['userPhotoUrl'];
    lastMessageId = json['lastMessageId'];
    lastMessage = json['lastMessage'];
    lastMessageTimestamp = json['lastMessageTimestamp'];
    lastMessageIsRead = json['lastMessageIsRead'];
    documentSnapshot = json['documentSnapshot'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'userPhotoUrl': userPhotoUrl,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessageIsRead': lastMessageIsRead,
    };
  }

  void update() {
    notifyListeners();
  }
}
