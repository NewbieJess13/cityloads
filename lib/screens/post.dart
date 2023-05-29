import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jiffy/jiffy.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './profile.dart';
import './loader.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart' as PostModel;
import '../helpers/notification.dart';

class Post extends StatefulWidget {
  final PostModel.Post post;
  const Post({Key key, this.post}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> {
  PostModel.Post post;
  String userId;
  String photoUrl;
  String firstName;
  String lastName;
  SharedPreferences prefs;
  bool isLoading = true;
  bool favoriteLoading = false;
  bool commentsLoading = true;
  int currentIndex = 0;
  Completer<GoogleMapController> mapController = Completer();
  CarouselController carouselController = CarouselController();

  List<Marker> markers = <Marker>[];
  List comments = [];
  String newComment = '';
  TextEditingController commentController = TextEditingController();
  bool showMap = false;

  List<Color> _colors = [Colors.black.withOpacity(0.75), Colors.transparent];
  List<double> _stops = [0.0, 1];
  ScrollController scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    post = widget.post;
    getPreferences();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    prefs.setString('currentScreen', '');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Loader()
        : Scaffold(
            appBar: AppBar(
                elevation: 0,
                title: Text('DETAILS',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                leading: IconButton(
                    splashRadius: 20.0,
                    icon: SvgPicture.asset(
                      'assets/icons/back_arrow.svg',
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop())),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: profile(),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        shadowColor: Colors.red,
                        elevation: 0.0,
                        automaticallyImplyLeading: false,
                        pinned: true,
                        expandedHeight: 300.0,
                        collapsedHeight: 150.0,
                        flexibleSpace: Stack(
                          alignment: AlignmentDirectional.bottomCenter,
                          children: [
                            CarouselSlider.builder(
                              carouselController: carouselController,
                              options: CarouselOptions(
                                  height: 345,
                                  viewportFraction: 1.0,
                                  enableInfiniteScroll: false,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      currentIndex = index;
                                    });
                                  }),
                              itemCount: post.images.length,
                              itemBuilder:
                                  (BuildContext context, int itemIndex) =>
                                      Container(
                                color: Colors.black,
                                width: MediaQuery.of(context).size.width,
                                child: CachedNetworkImage(
                                  imageUrl: post.images[itemIndex],
                                  imageBuilder: (context, imageProvider) =>
                                      GestureDetector(
                                    onTap: () => {openGallery(itemIndex)},
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                        height: 30.0,
                                        width: 30.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        )),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0.0,
                              left: 0.0,
                              child: Container(
                                height: 100,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: _colors,
                                    stops: _stops,
                                  ),
                                ),
                              ),
                            ),
                            post.images.length < 2
                                ? Container(
                                    height: 0.0,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int index = 0;
                                          index <= post.images.length - 1;
                                          index++)
                                        Container(
                                          width: 35.0,
                                          height: 4,
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 2.0),
                                          decoration: BoxDecoration(
                                            color: currentIndex == index
                                                ? Colors.white
                                                : Colors.black
                                                    .withOpacity(0.35),
                                          ),
                                        )
                                    ],
                                  )
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(left: 15.0, right: 15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Text(
                                              post.title.toUpperCase(),
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.3),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Text(
                                            currency + formatNumber(post.price),
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Text(
                                      'Built in ' + post.year,
                                      style: TextStyle(
                                          fontSize: 16.0, height: 1.5),
                                    ),
                                    Container(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 5.0),
                                            child: Icon(
                                                Ionicons.location_outline,
                                                size: 20.0,
                                                color: Colors.black45),
                                          ),
                                          Expanded(
                                              child: Padding(
                                            padding: EdgeInsets.only(left: 5.0),
                                            child: Text(
                                              post.location,
                                              style: TextStyle(
                                                  fontSize: 16.0, height: 1.5),
                                            ),
                                          )),
                                          Container(
                                            child: post.userId != userId
                                                ? post.isFavoriteLoading
                                                    ? Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 5,
                                                                right: 15.0,
                                                                left: 15),
                                                        child: SizedBox(
                                                            width: 20.0,
                                                            height: 20.0,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 1,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .black),
                                                            )),
                                                      )
                                                    : Transform.translate(
                                                        offset: Offset(0, -10),
                                                        child: IconButton(
                                                          onPressed: () => {
                                                            toggleFavorite()
                                                          },
                                                          splashRadius: 20.0,
                                                          icon: Icon(
                                                            post.isFavorite ==
                                                                    true
                                                                ? Ionicons.heart
                                                                : Ionicons
                                                                    .heart_outline,
                                                            color:
                                                                post.isFavorite ==
                                                                        true
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .black,
                                                            size: 30.0,
                                                          ),
                                                        ))
                                                : Container(
                                                    height: 0.0,
                                                  ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 20.0),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom:
                                            BorderSide(color: Colors.black12))),
                                child: postAttributes(),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 20.0, left: 15.0, right: 15.0),
                                child: Text(
                                  'DESCRIPTION',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 10.0, left: 15.0, right: 15.0),
                                child: Text(
                                  post.description,
                                  style: TextStyle(fontSize: 16.0, height: 1.4),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 20.0, left: 15.0, right: 15.0),
                                child: Text(
                                  'LOCATION',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                height: 250.0,
                                color: Colors.black12,
                                margin: EdgeInsets.only(
                                  top: 20.0,
                                ),
                                child: showMap
                                    ? GoogleMap(
                                        myLocationButtonEnabled: false,
                                        markers: Set<Marker>.of(markers),
                                        initialCameraPosition: CameraPosition(
                                            zoom: 14.0,
                                            target:
                                                LatLng(post.lat, post.long)),
                                        onMapCreated:
                                            (GoogleMapController controller) {
                                          mapController.complete(controller);
                                        },
                                      )
                                    : Center(
                                        child: SizedBox(
                                            height: 20.0,
                                            width: 20.0,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Theme.of(context)
                                                          .primaryColor),
                                            )),
                                      ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 20.0,
                                    left: 15.0,
                                    right: 15.0,
                                    bottom: 15.0),
                                child: Text(
                                  'COMMENTS',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              commentsList(),
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        top:
                                            BorderSide(color: Colors.black12))),
                                padding: EdgeInsets.only(
                                    left: 15.0, right: 15.0, bottom: 30.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                          controller: commentController,
                                          maxLines: 3,
                                          minLines: 1,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16.0),
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              hintText: 'Leave a comment..'),
                                          onChanged: (String value) {
                                            newComment = value.trim();
                                          }),
                                    ),
                                    IconButton(
                                      splashRadius: 20.0,
                                      icon: Icon(
                                        FontAwesomeIcons.paperPlane,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () => {submitComment()},
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
  }

  String formatNumber(number) {
    NumberFormat format = NumberFormat("#,###.00", "en_US");
    return format.format(double.parse(number));
  }

  submitComment() async {
    if (newComment.isNotEmpty) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      post.documentSnapshot.reference.collection('comments').add(
          {'userId': userId, 'comment': newComment, 'timestamp': timestamp});
      comments.insert(0, {
        'userPhotoUrl': photoUrl,
        'userFullName': "$firstName $lastName",
        'comment': newComment,
        'timestamp': timestamp
      });
      if (post.userId != userId) {
        SendNotification(post.userId, 'Post Comment',
            '$firstName $lastName has commented on your post', {
          'type': 'post_comment',
          'targetUserId': post.userId,
          'post': jsonEncode(post.toJson())
        });
      }
      commentController.text = '';
      setState(() {
        newComment = '';
      });
    }
  }

  Widget commentsList() {
    if (commentsLoading)
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 50.0),
          child: SizedBox(
              height: 20.0,
              width: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              )),
        ),
      );

    if (comments.length == 0)
      return Padding(
        padding: EdgeInsets.only(bottom: 30.0),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            'No comments..',
            style: TextStyle(color: Colors.black38, fontSize: 15.0),
            textAlign: TextAlign.center,
          ),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var comment in comments)
          Padding(
            padding: EdgeInsets.only(bottom: 30.0, left: 15.0, right: 15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                renderProfilePicture(comment['userPhotoUrl']),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['userFullName'],
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17.0),
                        ),
                        Text(parseTimestamp(comment['timestamp']),
                            style: TextStyle(
                                fontWeight: FontWeight.w300, fontSize: 14.0)),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Container(
                            child: Text(comment['comment'],
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 14.0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
      ],
    );
  }

  Widget renderProfilePicture(String photoUrl) {
    Widget profilePicture = (photoUrl != null)
        ? CircleAvatar(
            radius: 20.0,
            backgroundImage: CachedNetworkImageProvider(photoUrl),
          )
        : CircleAvatar(
            radius: 20.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          );
    return profilePicture;
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      photoUrl = prefs.getString('photoUrl');
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      prefs.setString('currentScreen', 'post-${post.id}');
    });

    if (post.id != null && post.documentSnapshot == null) {
      DocumentSnapshot postUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(post.userId)
          .get();
      DocumentSnapshot postDoc =
          await postUserDoc.reference.collection('posts').doc(post.id).get();

      if (postUserDoc == null || postDoc == null) return;

      post.documentSnapshot = postDoc;
      post.update();
    }

    setState(() {
      isLoading = false;
    });

    markers.add(Marker(
        markerId: MarkerId('position'), position: LatLng(post.lat, post.long)));

    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        showMap = true;
      });
    });

    getPostFavorite();
    getComments();
  }

  getPostFavorite() async {
    post.documentSnapshot.reference
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get()
        .then((favoriteSnapshot) {
      List<QueryDocumentSnapshot> favoriteDoc = favoriteSnapshot.docs;
      if (favoriteDoc.length > 0) {
        post.isFavorite = true;
      } else {
        post.isFavorite = false;
      }
      post.update();
    });
  }

  getComments() async {
    List newComments = [];
    QuerySnapshot querySnapshot =
        await post.documentSnapshot.reference.collection('comments').get();
    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> comment = doc.data();
        QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: comment['userId'])
            .limit(1)
            .get();

        if (result.docs.length > 0) {
          String photoUrl = result.docs[0].get('photoUrl');
          String fullName = result.docs[0].get('firstName') +
              ' ' +
              result.docs[0].get('lastName');
          comment['userPhotoUrl'] = photoUrl;
          comment['userFullName'] = fullName;
          newComments.add(comment);
        }
      }
    }

    setState(() {
      comments = newComments;
      commentsLoading = false;
    });

    if (post.scrollToComments == true) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(700.0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn);
      });
    }
  }

  toggleFavorite() async {
    if (post.userId == userId) return;

    setState(() {
      post.isFavoriteLoading = true;
    });

    bool isFavorite;
    if (post.isFavorite == false) {
      await post.documentSnapshot.reference
          .collection('favorites')
          .add({'userId': userId});
      isFavorite = true;
    } else {
      QuerySnapshot favorite = await post.documentSnapshot.reference
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      List<QueryDocumentSnapshot> favoritesResult = favorite.docs;
      for (int i = 0; i < favoritesResult.length; i++) {
        await post.documentSnapshot.reference
            .collection('favorites')
            .doc(favoritesResult[i].id)
            .delete();
      }
      isFavorite = false;
    }

    setState(() {
      post.isFavorite = isFavorite;
      post.isFavoriteLoading = false;
    });
    post.update();
  }

  Widget profile() {
    Widget profilePicture = (post.userPhotoUrl != null)
        ? CircleAvatar(
            radius: 18.0,
            backgroundImage: CachedNetworkImageProvider(post.userPhotoUrl),
          )
        : CircleAvatar(
            radius: 18.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
            padding: EdgeInsets.only(
              bottom: 15.0,
            ),
            child: GestureDetector(
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Profile(
                            userId: post.userId,
                          )),
                )
              },
              child: Row(
                children: [
                  Stack(
                    children: [profilePicture, onlineStatus()],
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userFullName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17.0),
                        ),
                        Text(parseTimestamp(post.timestamp),
                            style: TextStyle(
                                fontWeight: FontWeight.w300, fontSize: 14.0)),
                      ],
                    ),
                  )
                ],
              ),
            )),
      ],
    );
  }

  StreamBuilder<DocumentSnapshot> onlineStatus() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(post.userId)
          .snapshots(),
      builder: (context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData &&
            snapshot.data.data()['isOnline'] == true &&
            post.userId != userId) {
          return Positioned(
            bottom: 0.0,
            right: 0.0,
            child: Container(
              width: 11.0,
              height: 11.0,
              decoration: BoxDecoration(
                  color: Color(0XFF27AE60),
                  border: Border.all(color: Colors.white, width: 1.6),
                  borderRadius: BorderRadius.circular(50.0)),
            ),
          );
        }

        return Container(
          height: 0.0,
        );
      },
    );
  }

  String parseTimestamp(timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return Jiffy(date).fromNow();
  }

  Widget postAttributes() {
    List<Widget> attributes = [];
    int bedrooms = post.bedrooms;
    int baths = post.baths;
    bool parking = post.parking;
    int floors = post.floors;

    attributes.add(Column(
      children: [
        Container(
          padding: EdgeInsets.all(7.0),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(50.0)),
          child: Icon(
            FontAwesomeIcons.squareFull,
            size: 15.0,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0, bottom: 8.0),
          child: Text(
            post.size + ' sqft',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
          ),
        ),
      ],
    ));

    attributes.add(Opacity(
      opacity: bedrooms > 0 ? 1.0 : 0.35,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(50.0)),
            child: Icon(
              FontAwesomeIcons.bed,
              size: 15.0,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 8.0),
            child: Text(
              bedrooms.toString() + ' rooms',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
            ),
          ),
        ],
      ),
    ));

    attributes.add(Opacity(
      opacity: baths > 0 ? 1.0 : 0.35,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(50.0)),
            child: Icon(
              FontAwesomeIcons.bath,
              size: 15.0,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 8.0),
            child: Text(
              baths.toString() + ' baths',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
            ),
          ),
        ],
      ),
    ));

    attributes.add(Opacity(
      opacity: parking ? 1.0 : 0.35,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(50.0)),
            child: Icon(
              FontAwesomeIcons.parking,
              size: 15.0,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 8.0),
            child: Text(
              'Parking',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
            ),
          ),
        ],
      ),
    ));

    attributes.add(Opacity(
      opacity: floors > 0 ? 1.0 : 0.35,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(50.0)),
            child: Icon(
              FontAwesomeIcons.layerGroup,
              size: 15.0,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 8.0),
            child: Text(
              floors.toString() + ' floors',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
            ),
          ),
        ],
      ),
    ));

    return Padding(
      padding: EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [...attributes],
      ),
    );
  }

  String get currency {
    String currencySymbol;
    switch (post.currency) {
      case 'USD':
        currencySymbol = '\$';
        break;
      case 'EUR':
        currencySymbol = '€';
        break;
      case 'GBP':
        currencySymbol = '£';
        break;
      case 'CNY':
      case 'JPY':
        currencySymbol = ' ¥';
        break;
      case 'AED':
        currencySymbol = 'د.إ';
        break;
      case 'SAR':
        currencySymbol = '﷼‎';
        break;
      default:
        currencySymbol = '\$';
    }

    return currencySymbol;
  }

  openGallery(int index) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        enableDrag: true,
        builder: (BuildContext context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                color: Colors.black,
                padding: EdgeInsets.only(top: 30.0, bottom: 20.0),
                child: Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    centerTitle: false,
                    leading: Builder(
                      builder: (BuildContext context) {
                        return IconButton(
                            splashRadius: 20.0,
                            icon: Icon(
                              Ionicons.close_outline,
                              color: Colors.white,
                              size: 30.0,
                            ),
                            onPressed: () => Navigator.of(context).pop());
                      },
                    ),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  body: CarouselSlider.builder(
                    options: CarouselOptions(
                        height: MediaQuery.of(context).size.height,
                        initialPage: index,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        onPageChanged: (index, reason) {
                          setState(() {
                            currentIndex = index;
                            carouselController.jumpToPage(index);
                          });
                        }),
                    itemCount: post.images.length,
                    itemBuilder: (BuildContext context, int itemIndex) =>
                        Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      child: CachedNetworkImage(
                        imageUrl: post.images[itemIndex],
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                              height: 30.0,
                              width: 30.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              );
            }));
  }
}
