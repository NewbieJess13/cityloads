import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Post extends ChangeNotifier {
  String? id;
  int? bedrooms;
  String? location;
  String? userId;
  String? title;
  List<String>? images;
  String? rentPeriod;
  String? year;
  double? long;
  String? availableFor;
  String? size;
  List? types;
  String? timestamp;
  int? baths;
  int? floors;
  double? lat;
  String? interior;
  bool? parking;
  String? currency;
  String? price;
  bool? maid;
  String? description;
  bool? isFavorite;
  late bool isFavoriteLoading;
  String? userPhotoUrl;
  String? userFullName;
  DocumentSnapshot? documentSnapshot;
  bool? scrollToComments;

  Post(
      {this.id,
      this.bedrooms,
      this.location,
      this.userId,
      this.title,
      this.images,
      this.rentPeriod,
      this.year,
      this.long,
      this.availableFor,
      this.size,
      this.types,
      this.timestamp,
      this.baths,
      this.floors,
      this.lat,
      this.interior,
      this.parking,
      this.currency,
      this.price,
      this.maid,
      this.description,
      this.isFavorite,
      this.isFavoriteLoading = false,
      this.userPhotoUrl,
      this.userFullName,
      this.documentSnapshot,
      this.scrollToComments});

  Post.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bedrooms = json['bedrooms'];
    location = json['location'];
    userId = json['userId'];
    title = json['title'];
    images = json['images'].cast<String>();
    rentPeriod = json['rentPeriod'];
    year = json['year'];
    long = json['long'];
    availableFor = json['availableFor'];
    size = json['size'];
    if (json['types'] != null) {
      types = [];
      jsonDecode(json['types']).forEach((v) {
        types!.add(v);
      });
    }
    timestamp = json['timestamp'];
    baths = json['baths'];
    floors = json['floors'];
    lat = json['lat'];
    interior = json['interior'];
    parking = json['parking'];
    currency = json['currency'];
    price = json['price'];
    maid = json['maid'];
    description = json['description'];
    isFavorite = json['isFavorite'];
    isFavoriteLoading = json['isFavoriteLoading'] ?? false;
    userPhotoUrl = json['userPhotoUrl'];
    userFullName = json['userFullName'];
    documentSnapshot = json['documentSnapshot'];
    scrollToComments = json['scrollToComments'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedrooms': bedrooms,
      'location': location,
      'userId': userId,
      'title': title,
      'images': images,
      'rentPeriod': rentPeriod,
      'year': year,
      'long': long,
      'availableFor': availableFor,
      'size': size,
      'types': jsonEncode(types),
      'timestamp': timestamp,
      'baths': baths,
      'floors': floors,
      'lat': lat,
      'interior': interior,
      'parking': parking,
      'currency': currency,
      'price': price,
      'maid': maid,
      'description': description,
      'isFavorite': isFavorite,
      'isFavoriteLoading': isFavoriteLoading,
      'userPhotoUrl': userPhotoUrl,
      'userFullName': userFullName,
      'scrollToComments': scrollToComments,
    };
  }

  void update() {
    notifyListeners();
  }
}
