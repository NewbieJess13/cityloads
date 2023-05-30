import 'package:flutter/material.dart';

class Article extends ChangeNotifier {
  String? url;
  String? title;
  String? description;
  String? pubDate;
  String? photoUrl;
  String? favoriteNewsId;
  bool? isFavoriteLoading;

  Article(
      {this.url,
      this.title,
      this.description,
      this.pubDate,
      this.photoUrl,
      this.favoriteNewsId,
      this.isFavoriteLoading});

  Article.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    title = json['title'];
    description = json['description'];
    pubDate = json['pubDate'];
    photoUrl = json['photoUrl'];
    favoriteNewsId = json['favoriteNewsId'];
    isFavoriteLoading = json['isFavoriteLoading'];
  }

  void update() {
    notifyListeners();
  }
}
