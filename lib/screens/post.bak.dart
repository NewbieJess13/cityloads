import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jiffy/jiffy.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './profile.dart';
import 'dart:async';
import '../models/post.dart' as PostModel;

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
  bool isLoading = false;
  bool favoriteLoading = false;
  bool commentsLoading = true;
  int currentIndex = 0;
  Completer<GoogleMapController> mapController = Completer();

  List<Marker> markers = <Marker>[];
  List comments = [];
  String newComment = '';
  TextEditingController commentController = TextEditingController();
  bool showMap = false;

  @override
  initState() {
    super.initState();
    post = widget.post;
    getPreferences();
    markers.add(Marker(
        markerId: MarkerId('position'), position: LatLng(post.lat, post.long)));
    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        showMap = true;
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
                splashRadius: 20.0,
                icon: Icon(
                  Ionicons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(post));
          },
        ),
        title: Text('DETAILS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 22.0)),
        actions: [
          // IconButton(
          //   onPressed: () => {},
          //   splashRadius: 20.0,
          //   icon: Icon(
          //     FontAwesomeIcons.ellipsisH,
          //     color: Colors.black,
          //     size: 20.0,
          //   ),
          // )
        ],
      ),
      body: isLoading
          ? Loader()
          : LayoutBuilder(
              builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: Container(
                      margin: EdgeInsets.only(top: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profile(),
                          Container(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Column(
                              children: [
                                CarouselSlider.builder(
                                  options: CarouselOptions(
                                      height:
                                          MediaQuery.of(context).size.width -
                                              104,
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
                                post.images.length < 2
                                    ? Container(
                                        height: 0.0,
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (int index = 0;
                                              index <= post.images.length - 1;
                                              index++)
                                            Container(
                                              width: 35.0,
                                              height: 3.5,
                                              margin: EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 2.0),
                                              decoration: BoxDecoration(
                                                color: currentIndex == index
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.35),
                                              ),
                                            )
                                        ],
                                      )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: 15.0,
                                left: 15.0,
                                right: 15.0,
                                bottom: 10.0),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          post.title.toString().toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 22.0,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        '\$' + post.price.toString(),
                                        style: TextStyle(
                                            fontSize: 22.0,
                                            fontWeight: FontWeight.w700),
                                      )
                                    ],
                                  ),
                                  Text(
                                    'Built in ' + post.year,
                                    style:
                                        TextStyle(fontSize: 16.0, height: 1.5),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 15.0, bottom: 15.0),
                                          child: RichText(
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            text: TextSpan(
                                              children: [
                                                WidgetSpan(
                                                  child: Icon(
                                                      FontAwesomeIcons
                                                          .mapMarkerAlt,
                                                      size: 13.0,
                                                      color: Colors.black38),
                                                ),
                                                TextSpan(
                                                  text: ' ' + post.location,
                                                  style: TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.black54,
                                                      fontFamily: 'Raleway'),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      post.userId != userId
                                          ? post.isFavoriteLoading
                                              ? Container(
                                                  padding: EdgeInsets.only(
                                                      left: 5.0, right: 12.0),
                                                  child: SizedBox(
                                                      width: 25.0,
                                                      height: 25.0,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 1,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.black26),
                                                      )),
                                                )
                                              : IconButton(
                                                  onPressed: () =>
                                                      {toggleFavorite()},
                                                  splashRadius: 20.0,
                                                  icon: Icon(
                                                    post.isFavorite == true
                                                        ? FontAwesomeIcons
                                                            .solidHeart
                                                        : FontAwesomeIcons
                                                            .heart,
                                                    color:
                                                        post.isFavorite == true
                                                            ? Colors.red
                                                            : Colors.black45,
                                                    size: 25.0,
                                                  ),
                                                )
                                          : Container(
                                              height: 0.0,
                                            )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.black12))),
                            child: postAttributes(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, left: 15.0, right: 15.0),
                            child: Text(
                              'DESCRIPTION',
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.w700),
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
                                  fontSize: 20.0, fontWeight: FontWeight.w700),
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
                                        target: LatLng(post.lat, post.long)),
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
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Theme.of(context).primaryColor),
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
                                  fontSize: 20.0, fontWeight: FontWeight.w700),
                            ),
                          ),
                          commentsList(),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: Colors.black12))),
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
                  ),
                );
              },
            ),
    );
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      photoUrl = prefs.getString('photoUrl');
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
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

        String photoUrl = result.docs[0].get('photoUrl');
        String fullName = result.docs[0].get('firstName') +
            ' ' +
            result.docs[0].get('lastName');
        comment['userPhotoUrl'] = photoUrl;
        comment['userFullName'] = fullName;
        newComments.add(comment);
      }
    }

    setState(() {
      comments = newComments;
      commentsLoading = false;
    });
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
            radius: 20.0,
            backgroundImage: CachedNetworkImageProvider(post.userPhotoUrl),
          )
        : CircleAvatar(
            radius: 20.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 15.0),
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
                  profilePicture,
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
}
