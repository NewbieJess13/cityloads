import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tags/flutter_tags.dart';
import 'package:jiffy/jiffy.dart';
import 'package:flutter_range_slider_ns/flutter_range_slider_ns.dart' as frs;
import 'package:provider/provider.dart';
import './post.dart';
import '../widgets/number_picker.dart';
import '../models/post.dart' as PostModel;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class Feed extends StatefulWidget {
  // final String currentUserId;
  // Feed({Key key, @required this.currentUserId}) : super(key: key);
  final String city;
  final String isoCode;
  Feed({Key key, this.city, this.isoCode}) : super(key: key);
  @override
  State<StatefulWidget> createState() => FeedState();
}

class FeedState extends State<Feed> {
  bool postsLoading = true;
  bool postUsersLoading = true;
  bool postFavoritesLoading = true;
  String userId;
  SharedPreferences prefs;
  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  FirebaseAuth firebaseAuth;
  final GlobalKey<TagsState> _tagStateKey = GlobalKey<TagsState>();
  final GlobalKey<TagsState> _searchTagStateKey = GlobalKey<TagsState>();
  TextEditingController searchLocationController = TextEditingController();

  List searchTags;

  List types;
  Map<String, dynamic> search = {
    'location': '',
    'lowerYear': '1',
    'upperYear': '20',
    'bedrooms': 0,
    'baths': 0,
    'maid': false,
    'availableFor': 'rent',
    'rentPeriod': 'annual',
    'interior': 'furnished',
  };
  double lowerBudget = 10000.00;
  double upperBudget = 100000.00;
  List posts = [];

  @override
  void initState() {
    super.initState();
    getPreferences();
    types = [];
    searchTags = [];
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/back_arrow.svg',
              height: 20,
              width: 20,
            ),
            onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: false,
        title: Text('DISCOVER',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 26.0)),
        actions: [
          IconButton(
              onPressed: () => {openSearch()},
              splashRadius: 20.0,
              icon: SvgPicture.asset(
                'assets/icons/search.svg',
                height: 25,
                width: 25,
              ))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12))),
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: typeTags(),
          ),
          Flexible(
            child: postsLoading || postUsersLoading || postFavoritesLoading
                ? Center(
                    child: SizedBox(
                        height: 30.0,
                        width: 30.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                        )),
                  )
                : posts.length == 0
                    ? Center(
                        child: Text(
                        'No posts found.',
                        style: TextStyle(fontSize: 17.0, color: Colors.black54),
                      ))
                    : ListView.builder(
                        itemBuilder: (context, index) {
                          return buildItem(posts[index]);
                        },
                        itemCount: posts.length,
                      ),
          )
        ],
      ),
    );
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    if (widget.city != '' && widget.isoCode != '' ||
        widget.city != null && widget.isoCode != null) {
      getPostsFromCountrySelector(widget.city, widget.isoCode);
    } else
      getPosts();
  }

  getPostsFromCountrySelector(String city, String countryCode) async {
    setState(() {
      posts = [];
      postsLoading = true;
      postUsersLoading = true;
      postFavoritesLoading = true;
    });
    List newPosts = [];
    QuerySnapshot result =
        await FirebaseFirestore.instance.collectionGroup('posts').get();
    final List<DocumentSnapshot> queryPosts = result.docs;
    for (int i = 0; i < queryPosts.length; i++) {
      Map<String, dynamic> post = queryPosts[i].data();
      if (post['mappedAddress'] != null) {
        if (post['mappedAddress']['isoCountryCode'] == countryCode &&
            post['mappedAddress']['locality'] == city) {
          List parsedTypes = [];
          for (int i = 0; i <= types.length - 1; i++) {
            parsedTypes.add(types[i]['title']);
          }

          post['documentSnapshot'] = queryPosts[i];
          post['id'] = queryPosts[i].id;
          post['userId'] = queryPosts[i].reference.parent.parent.id;
          post['isFavorite'] = null;
          post['isFavoriteLoading'] = false;
          post['types'] = jsonEncode(post['types']);

          PostModel.Post postModel = PostModel.Post.fromJson(post);

          newPosts.add(postModel);
        }
      }
    }
    newPosts.sort((a, b) {
      return b.timestamp.compareTo(a.timestamp);
    });
    setState(() {
      posts = newPosts;
    });

    setState(() {
      postsLoading = false;
    });

    if (posts.length == 0) {
      return setState(() {
        postUsersLoading = false;
        postFavoritesLoading = false;
      });
    } else {
      getPostUsers();
      getPostFavorites();
    }
  }

  getPosts([Map<String, dynamic> searchQuery]) async {
    setState(() {
      posts = [];
      postsLoading = true;
      postUsersLoading = true;
      postFavoritesLoading = true;
    });
    List newPosts = [];
    QuerySnapshot result =
        await FirebaseFirestore.instance.collectionGroup('posts').get();
    final List<DocumentSnapshot> queryPosts = result.docs;
    for (int i = 0; i < queryPosts.length; i++) {
      Map<String, dynamic> post = queryPosts[i].data();
      if (searchQuery != null) {
        double postPrice = double.parse(post['price']);
        int postYear = int.parse(post['year']);
        int postRooms = post['bedrooms'];
        int postBaths = post['baths'];
        bool maid = post['maid'];

        final f = DateFormat('y');
        int yearNow = int.parse(f.format(DateTime.now()));
        int yearDifference = yearNow - postYear;

        List parsedTypes = [];
        for (int i = 0; i <= types.length - 1; i++) {
          parsedTypes.add(types[i]['title']);
        }

        bool locationFound = post['location'].contains(
            RegExp(r'' + searchQuery['location'], caseSensitive: false));
        bool budgetFound = postPrice >= lowerBudget.round() &&
            postPrice <= upperBudget.round();
        bool yearFound = yearDifference >=
                double.parse(searchQuery['lowerYear']).round() &&
            yearDifference <= double.parse(searchQuery['upperYear']).round();
        bool typesFound = parsedTypes.length == 0
            ? true
            : parsedTypes.any((item) => post['types'].toList().contains(item));
        bool bedroomsFound = searchQuery['bedrooms'] == postRooms;
        bool bathsFound = searchQuery['baths'] == postBaths;
        bool maidFound = searchQuery['maid'] == maid;
        bool availableForFound =
            searchQuery['availableFor'] == post['availableFor'];
        bool rentPeriodFound = searchQuery['rentPeriod'] == post['rentPeriod'];
        bool interiorFound = searchQuery['interior'] == post['interior'];

        if (!locationFound ||
            !budgetFound ||
            !yearFound ||
            !typesFound ||
            !bedroomsFound ||
            !bathsFound ||
            !maidFound ||
            !availableForFound ||
            !rentPeriodFound ||
            !interiorFound) continue;
      }

      post['documentSnapshot'] = queryPosts[i];
      post['id'] = queryPosts[i].id;
      post['userId'] = queryPosts[i].reference.parent.parent.id;
      post['isFavorite'] = null;
      post['isFavoriteLoading'] = false;
      post['types'] = jsonEncode(post['types']);

      PostModel.Post postModel = PostModel.Post.fromJson(post);

      newPosts.add(postModel);
    }
    newPosts.sort((a, b) {
      return b.timestamp.compareTo(a.timestamp);
    });
    setState(() {
      posts = newPosts;
    });

    setState(() {
      postsLoading = false;
    });

    if (posts.length == 0) {
      return setState(() {
        postUsersLoading = false;
        postFavoritesLoading = false;
      });
    } else {
      getPostUsers();
      getPostFavorites();
    }
  }

  getPostUsers() async {
    int completedCount = 0;
    List queriedUsers = [];
    posts.forEach((post) {
      var postUserSnapshot = queriedUsers.firstWhere(
          (element) =>
              element.id == post.documentSnapshot.reference.parent.parent.id,
          orElse: () => null);
      if (postUserSnapshot == null) {
        post.documentSnapshot.reference.parent.parent
            .get()
            .then((postUserSnapshot) {
          Map<String, dynamic> postUser = postUserSnapshot.data();
          post.userPhotoUrl = postUser['photoUrl'];
          post.userFullName =
              '${postUser['firstName']} ${postUser['lastName']}';
          completedCount++;
          if (completedCount == posts.length) {
            setState(() {
              postUsersLoading = false;
            });
          }
        });
      } else {
        Map<String, dynamic> postUser = postUserSnapshot.data();
        post.userPhotoUrl = postUser['photoUrl'];
        post.userFullName = '${postUser['firstName']} ${postUser['lastName']}';
        completedCount++;
        if (completedCount == posts.length) {
          setState(() {
            postUsersLoading = false;
          });
        }
      }
    });
  }

  getPostFavorites() async {
    int completedCount = 0;
    posts.forEach((post) {
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
        completedCount++;
        if (completedCount == posts.length) {
          setState(() {
            postFavoritesLoading = false;
          });
        }
      });
    });
  }

  StreamBuilder<DocumentSnapshot> onlineStatus(PostModel.Post post) {
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

  Widget buildItem(PostModel.Post post) {
    Widget profilePicture = (post.userPhotoUrl != null)
        ? CircleAvatar(
            radius: 20.0,
            backgroundImage: CachedNetworkImageProvider(post.userPhotoUrl),
          )
        : CircleAvatar(
            radius: 20.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          );

    return ChangeNotifierProvider.value(
      value: post,
      child: Consumer<PostModel.Post>(
        builder: (context, value, child) {
          return InkWell(
            onTap: () => {goToPost(post)},
            child: Container(
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12))),
              padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Row(
                          children: [
                            Stack(
                              children: [profilePicture, onlineStatus(post)],
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.userFullName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17.0),
                                  ),
                                  Text(
                                    parseTimestamp(post.timestamp),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        fontSize: 14.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // IconButton(
                      //   splashRadius: 20.0,
                      //   icon: Icon(
                      //     Ionicons.ellipsis_horizontal,
                      //     color: Colors.black26,
                      //     size: 30.0,
                      //   ),
                      //   onPressed: () => {},
                      // )
                    ],
                  ),
                  postThumbnail(post),
                  postAttributes(post),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget postThumbnail(PostModel.Post post) {
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
    return Container(
      margin: EdgeInsets.only(top: 15.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      width: MediaQuery.of(context).size.width,
                      height: 170.0,
                      imageUrl: post.images[0],
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                    post.images.length > 1
                        ? Positioned(
                            top: 10.0,
                            right: 10.0,
                            child: Container(
                              padding: EdgeInsets.only(
                                  top: 5.0, bottom: 5.0, left: 8.0, right: 8.0),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(5.0)),
                              child: Row(
                                children: [
                                  Text(post.images.length.toString() + ' ',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: '',
                                          height: 1.25)),
                                  Transform(
                                    transform: Matrix4.translationValues(
                                        0.0, -1.0, 0.0),
                                    child: Icon(
                                      Ionicons.images_outline,
                                      color: Colors.white,
                                      size: 16.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 22.0, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Built in ' + post.year,
                      style: TextStyle(fontSize: 14.0, height: 1.5),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Ionicons.briefcase_outline,
                            size: 20.0, color: Colors.black45),
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Text(
                            'For${post.availableFor == "rent" ? " " + post.rentPeriod : ""} ${post.availableFor}',
                            style: TextStyle(fontSize: 14.0, height: 1.5),
                          ),
                        ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 5.0),
                            child: Icon(Ionicons.location_outline,
                                size: 20.0, color: Colors.black45),
                          ),
                          Expanded(
                              child: Padding(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(
                              post.location,
                              style: TextStyle(fontSize: 14.0, height: 1.5),
                            ),
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 8,
                          child: AutoSizeText(
                            currencySymbol + formatNumber(post.price),
                            softWrap: true,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 25.0,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                            ),
                          ),
                        ),
                        //Spacer(),

                        post.userId != userId
                            ? post.isFavoriteLoading == true
                                ? Padding(
                                    padding: EdgeInsets.only(
                                        left: 5.0, right: 12.0, top: 5.0),
                                    child: SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black26),
                                        )),
                                  )
                                : Expanded(
                                    flex: 2,
                                    child: IconButton(
                                      padding: new EdgeInsets.all(0.0),
                                      onPressed: () => {toggleFavorite(post)},
                                      highlightColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      icon: Icon(
                                        post.isFavorite == true
                                            ? Ionicons.heart
                                            : Ionicons.heart_outline,
                                        color: post.isFavorite == true
                                            ? Colors.red
                                            : Colors.black45,
                                        size: 30.0,
                                      ),
                                    ),
                                  )
                            : Container(
                                height: 0.0,
                              )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatNumber(number) {
    NumberFormat format = NumberFormat("#,###.00", "en_US");
    return format.format(double.parse(number));
  }

  toggleFavorite(PostModel.Post post) async {
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
    } else if (post.isFavorite == true) {
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

    post.isFavorite = isFavorite;
    post.isFavoriteLoading = false;
    post.update();
  }

  Widget postAttributes(PostModel.Post post) {
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
            Ionicons.square,
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
              Ionicons.bed,
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
      padding: EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [...attributes],
      ),
    );
  }

  String parseTimestamp(timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return Jiffy(date).fromNow();
  }

  goToPost(PostModel.Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Post(
                post: post,
              )),
    );
  }

  openSearch() {
    searchLocationController.text = search['location'];
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        enableDrag: false,
        builder: (BuildContext context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                margin: EdgeInsets.only(top: 30.0, bottom: 20.0),
                child: Scaffold(
                  appBar: AppBar(
                    centerTitle: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    title: Text('SEARCH',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18.0)),
                    actions: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            resetSearch();
                          },
                          splashRadius: 20.0,
                          icon: SvgPicture.asset('assets/icons/close.svg'))
                    ],
                  ),
                  body: LayoutBuilder(builder: (BuildContext context,
                      BoxConstraints viewportConstraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: viewportConstraints.maxHeight),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  margin: EdgeInsets.only(bottom: 40.0),
                                  child: TextField(
                                      controller: searchLocationController,
                                      autofocus: true,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18.0),
                                      decoration: InputDecoration(
                                          labelStyle: TextStyle(
                                              fontWeight: FontWeight.w300),
                                          labelText: 'Location'),
                                      onChanged: (String value) {
                                        setState(() {
                                          search['location'] = value.trim();
                                        });
                                      })),
                              Container(
                                  margin: EdgeInsets.only(bottom: 15.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'BUDGET',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Text(
                                        '\$' +
                                            lowerBudget.toStringAsFixed(0) +
                                            ' - \$' +
                                            upperBudget.toStringAsFixed(0),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                    ],
                                  )),

                              Container(
                                child: frs.RangeSlider(
                                  lowerValue: lowerBudget,
                                  min: 10000.00,
                                  upperValue: upperBudget,
                                  max: 1000000.00,
                                  divisions: null,
                                  valueIndicatorFormatter: null,
                                  onChanged: (lowerValue, upperValue) {
                                    setModalState(() {
                                      lowerBudget = lowerValue;
                                      upperBudget = upperValue;
                                    });
                                    setState(() {
                                      lowerBudget = lowerValue;
                                      upperBudget = upperValue;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                  margin:
                                      EdgeInsets.only(top: 40.0, bottom: 15.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'YEAR',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      Text(
                                        double.parse(search['lowerYear'])
                                                .toStringAsFixed(0) +
                                            ' - ' +
                                            double.parse(search['upperYear'])
                                                .toStringAsFixed(0),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                    ],
                                  )),
                              //TODO: be back

                              Container(
                                child: frs.RangeSlider(
                                  showValueIndicator: true,
                                  lowerValue: double.parse(search['lowerYear']),
                                  min: 1,
                                  upperValue: double.parse(search['upperYear']),
                                  max: 100,
                                  divisions: null,
                                  valueIndicatorFormatter: null,
                                  onChanged: (lowerValue, upperValue) {
                                    setModalState(() {
                                      search['lowerYear'] =
                                          lowerValue.toString();
                                      search['upperYear'] =
                                          upperValue.toString();
                                    });
                                    setState(() {
                                      search['lowerYear'] =
                                          lowerValue.toString();
                                      search['upperYear'] =
                                          upperValue.toString();
                                    });
                                  },
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(top: 40.0, bottom: 15.0),
                                child: Text(
                                  'TYPE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.0),
                                ),
                              ),
                              searchTypeTags(setModalState),
                              Container(
                                margin:
                                    EdgeInsets.only(top: 40.0, bottom: 15.0),
                                child: Text(
                                  'ROOMS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.0),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35.0,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            FontAwesomeIcons.bed,
                                            size: 16.0,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Bedroom',
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            color: Colors.black54),
                                      )
                                    ],
                                  ),
                                  NumberPicker(
                                    value: search['bedrooms'],
                                    onChange: (newValue) => {
                                      setState(
                                          () => {search['bedrooms'] = newValue})
                                    },
                                  )
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 35.0,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Icon(
                                              FontAwesomeIcons.bath,
                                              size: 16.0,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Baths',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    NumberPicker(
                                      value: search['baths'],
                                      onChange: (newValue) => {
                                        setState(
                                            () => {search['baths'] = newValue})
                                      },
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 35.0,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Icon(
                                              FontAwesomeIcons.userNurse,
                                              size: 16.0,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Maid Room',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 125.0,
                                      height: 24.0,
                                      child: Checkbox(
                                        value: search['maid'],
                                        onChanged: (newValue) {
                                          setState(() {
                                            search['maid'] = newValue;
                                          });
                                          setModalState(() {
                                            search['maid'] = newValue;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...availableForSelect(setModalState),
                              ...rentSelect(setModalState),
                              ...interiorSelect(setModalState),
                              searchBottomButtons()
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }));
  }

  Widget typeTags() {
    return Tags(
      runSpacing: 5.0,
      runAlignment: WrapAlignment.spaceEvenly,
      key: _tagStateKey,
      alignment: WrapAlignment.start,
      itemCount: types.length, // required
      itemBuilder: (int index) {
        final item = types[index];

        return ItemTags(
          padding: EdgeInsets.only(
            left: 10.0,
            right: 5.0,
            top: 5.0,
            bottom: 5.0,
          ),
          border: Border.all(color: Colors.black12),
          elevation: 0,
          pressEnabled: false,
          textActiveColor: Theme.of(context).primaryColor,
          activeColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(0)),
          key: Key(index.toString()),
          index: index, // required
          title: item['title'],
          active: item['active'],
          customData: item['customData'],
          textStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
          combine: ItemTagsCombine.withTextBefore,
          removeButton: ItemTagsRemoveButton(
            backgroundColor: Colors.white,
            color: Colors.black45,
            size: 20.0,
            onRemoved: () {
              setState(() {
                types.removeAt(index);
              });
              return true;
            },
          ), // OR null,
          onPressed: (item) => print(item),
          onLongPressed: (item) => print(item),
        );
      },
    );
  }

  Widget searchTypeTags(StateSetter setModalState) {
    return Tags(
      runSpacing: 5.0,
      runAlignment: WrapAlignment.spaceEvenly,
      key: _searchTagStateKey,
      textField: TagsTextField(
        inputDecoration: InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.only(
            left: 10.0,
            right: 5.0,
            top: 10.0,
            bottom: 10.0,
          ),
          suffixIcon: Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
            size: 18.0,
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 35.0),
          fillColor: Theme.of(context).primaryColor,
          filled: true,
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 0.0),
              borderRadius: BorderRadius.circular(0.0)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 0.0),
              borderRadius: BorderRadius.circular(0.0)),
        ),
        width: 115.0,
        hintText: 'Add New',
        hintTextColor: Colors.white.withOpacity(0.85),
        textStyle: TextStyle(fontSize: 14.0, color: Colors.white),
        onSubmitted: (String str) {
          setModalState(() {
            searchTags.addAll({
              {'title': str, 'active': true}
            });
          });
          setState(() {
            types.addAll({
              {'title': str, 'active': true}
            });
          });
        },
      ),
      alignment: WrapAlignment.start,
      itemCount: types.length, // required
      itemBuilder: (int index) {
        final item = types[index];

        return ItemTags(
          padding: EdgeInsets.only(
            left: 10.0,
            right: 5.0,
            top: 5.0,
            bottom: 5.0,
          ),
          border: Border.all(color: Colors.black12),
          elevation: 0,
          pressEnabled: false,
          textActiveColor: Theme.of(context).primaryColor,
          colorShowDuplicate: Colors.white,
          activeColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(0)),
          key: Key(index.toString()),
          index: index, // required
          title: item['title'],
          active: item['active'],
          customData: item['customData'],
          textStyle: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
          combine: ItemTagsCombine.withTextBefore,
          removeButton: ItemTagsRemoveButton(
            backgroundColor: Colors.white,
            color: Colors.black45,
            size: 20.0,
            onRemoved: () {
              setState(() {
                types.removeAt(index);
              });
              setModalState(() {
                searchTags.removeAt(index);
              });
              return true;
            },
          ), // OR null,
        );
      },
    );
  }

  List<Widget> availableForSelect(StateSetter setModalState) {
    return [
      Container(
          margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
          child: Text(
            'AVAILABLE FOR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          )),
      Container(
        padding: EdgeInsets.all(3.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: search['availableFor'] == 'rent'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('RENT',
                      style: TextStyle(
                          color: search['availableFor'] == 'rent'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () {
                    setState(() => {search['availableFor'] = 'rent'});
                    setModalState(() => {search['availableFor'] = 'rent'});
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: search['availableFor'] == 'sale'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('SALE',
                      style: TextStyle(
                          color: search['availableFor'] == 'sale'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () {
                    setState(() => {search['availableFor'] = 'sale'});
                    setModalState(() => {search['availableFor'] = 'sale'});
                  },
                ),
              ),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> rentSelect(StateSetter setModalState) {
    return [
      Opacity(
        opacity: search['availableFor'] == 'rent' ? 1.0 : 0.25,
        child: Container(
            margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
            child: Text(
              'RENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            )),
      ),
      AbsorbPointer(
        absorbing: search['availableFor'] == 'rent' ? false : true,
        child: Opacity(
          opacity: search['availableFor'] == 'rent' ? 1.0 : 0.25,
          child: Container(
            padding: EdgeInsets.all(3.0),
            decoration:
                BoxDecoration(border: Border.all(color: Colors.black12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: search['rentPeriod'] == 'annual'
                            ? Theme.of(context).primaryColor
                            : Colors.white),
                    child: ElevatedButton(
                      child: Text('ANNUAL',
                          style: TextStyle(
                              color: search['rentPeriod'] == 'annual'
                                  ? Colors.white
                                  : Colors.black54)),
                      onPressed: () {
                        setState(() => {search['rentPeriod'] = 'annual'});
                        setModalState(() => {search['rentPeriod'] = 'annual'});
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: search['rentPeriod'] == 'monthly'
                            ? Theme.of(context).primaryColor
                            : Colors.white),
                    child: ElevatedButton(
                      child: Text('MONTHLY',
                          style: TextStyle(
                              color: search['rentPeriod'] == 'monthly'
                                  ? Colors.white
                                  : Colors.black54)),
                      onPressed: () {
                        setState(() => {search['rentPeriod'] = 'monthly'});
                        setModalState(() => {search['rentPeriod'] = 'monthly'});
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    ];
  }

  List<Widget> interiorSelect(StateSetter setModalState) {
    return [
      Container(
          margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
          child: Text(
            'INTERIOR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          )),
      Container(
        padding: EdgeInsets.all(3.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: search['interior'] == 'furnished'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('FURNISHED',
                      style: TextStyle(
                          color: search['interior'] == 'furnished'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () {
                    setState(() => {search['interior'] = 'furnished'});
                    setModalState(() => {search['interior'] = 'furnished'});
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: search['interior'] == 'not_furnished'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('NOT FURNISHED',
                      style: TextStyle(
                          color: search['interior'] == 'not_furnished'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () {
                    setState(() => {search['interior'] = 'not_furnished'});
                    setModalState(() => {search['interior'] = 'not_furnished'});
                  },
                ),
              ),
            ),
          ],
        ),
      )
    ];
  }

  Widget searchBottomButtons() {
    return Container(
      margin: EdgeInsets.only(top: 40.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Material(
                child: InkWell(
                    onTap: () {
                      resetSearch(true);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12)),
                      child: Container(
                          margin: EdgeInsets.only(top: 17.0, bottom: 17.0),
                          child: Text('CANCEL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor))),
                    ))),
          ),
          Container(margin: EdgeInsets.only(left: 6, right: 6)),
          Expanded(
            child: Material(
                color: Theme.of(context).primaryColor,
                child: InkWell(
                    onTap: () {
                      if (search['location'].isNotEmpty) {
                        getPosts(search);
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                        margin: EdgeInsets.only(top: 17.0, bottom: 17.0),
                        child: Text('SEARCH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white))))),
          ),
        ],
      ),
    );
  }

  resetSearch([bool refresh]) {
    setState(() {
      search = {
        'location': '',
        'lowerBudget': '1000',
        'upperBudget': '10000',
        'lowerYear': '1',
        'upperYear': '20',
        'bedrooms': 0,
        'baths': 0,
        'maid': false,
        'availableFor': 'rent',
        'rentPeriod': 'annual',
        'interior': 'furnished',
      };
      types = [];
    });
    if (refresh == true) {
      searchLocationController.text = '';
      getPosts();
    }
  }
}
