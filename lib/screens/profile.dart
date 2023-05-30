import 'package:CityLoads/screens/help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as UserModel;
import '../models/post.dart' as PostModel;
import './post.dart';
import './login.dart';
import './messages.dart';
import 'user_settings.dart';
import '../models/conversation.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  final String? userId;
  const Profile({Key? key, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? currentUserId;
  UserModel.User? user;
  SharedPreferences? prefs;
  bool isLoading = true;
  bool contentLoading = true;
  bool hasMessageButton = false;
  bool? currentUser;
  Conversation? conversation;
  String contentType = 'posts';

  List posts = [];
  List favorites = [];
  List articles = [];

  int favoritesCount = 0;
  int articlesCount = 0;
  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  @override
  initState() {
    super.initState();
    getData();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                alignment: Alignment.topCenter,
                image: AssetImage("assets/images/profile_bg.png"),
                fit: BoxFit.contain)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leading: currentUser == false || widget.userId != null
                ? Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                          splashRadius: 20.0,
                          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
                          onPressed: () => Navigator.of(context).pop());
                    },
                  )
                : Container(),
            title: Text('PROFILE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 26.0)),
            actions: [
              currentUser == true
                  ? PopupMenuButton(
                      onSelected: (dynamic value) {
                        switch (value) {
                          case 'settings':
                            goToSettings();
                            break;
                          case 'help':
                            goToHelp();
                            break;

                          case 'logout':
                            logout();
                            break;
                        }
                      },
                      icon: SvgPicture.asset('assets/icons/settings_icon.svg'),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text("Account"),
                          value: 'settings',
                        ),
                        PopupMenuItem(
                          child: Text("Help"),
                          value: 'help',
                        ),
                        PopupMenuItem(
                          child: Text("Log Out"),
                          value: 'logout',
                        ),
                      ],
                    )
                  : Container()
            ],
          ),
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              isLoading
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
                  : LayoutBuilder(
                      builder: (BuildContext context,
                          BoxConstraints viewportConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                profileInfo(),
                                ...content(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              messageButton()
            ],
          ),
        ));
  }

  Widget messageButton() {
    if (!hasMessageButton) return Container();
    bool currentUser = widget.userId == currentUserId || widget.userId == null;
    if (contentLoading || currentUser)
      return Container(
        height: 0.0,
      );

    return Padding(
      padding: EdgeInsets.only(bottom: 35.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding:
              EdgeInsets.only(top: 18.0, bottom: 18.0, right: 40.0, left: 40.0),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text('SEND MESSAGE', style: TextStyle(color: Colors.white)),
        onPressed: () => {goToMessages()},
      ),
    );
  }

  List<Widget> content() {
    if (contentLoading)
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: 250.0),
            child: SizedBox(
                height: 25.0,
                width: 25.0,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                )),
          ),
        )
      ];
    return [reports(), renderContent()];
  }

  getData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs!.getString('userId');
    });

    setState(() {
      currentUser = widget.userId == currentUserId || widget.userId == null;
    });
    String? userId = widget.userId;
    user = UserModel.User();
    if (userId == null) {
      user!.id = currentUserId;
    } else {
      user!.id = userId;
    }

    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.id)
            .get();

    if (userSnapshot.data() == null) return;

    user!.firstName = userSnapshot.data()!['firstName'];
    user!.lastName = userSnapshot.data()!['lastName'];
    user!.email = userSnapshot.data()!['email'];
    user!.photoUrl = userSnapshot.data()!['photoUrl'];
    user!.emailNotifications = userSnapshot.data()!['emailNotifications'];

    await getConversation();

    setState(() {
      hasMessageButton = true;
      isLoading = false;
    });

    QuerySnapshot postsResult =
        await userSnapshot.reference.collection('posts').get();

    List newPosts = [];

    final List<DocumentSnapshot> queryPosts = postsResult.docs;

    for (int i = 0; i < queryPosts.length; i++) {
      Map<String, dynamic> post = queryPosts[i].data() as Map<String, dynamic>;
      post['id'] = queryPosts[i].id;
      post['userId'] = queryPosts[i].reference.parent.parent!.id;
      post['isFavorite'] = false;
      post['isFavoriteLoading'] = false;
      post['userPhotoUrl'] = user!.photoUrl;
      post['userFullName'] = "${user!.firstName} ${user!.lastName}";
      post['documentSnapshot'] = queryPosts[i];
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

    List newFavorites = [];
    QuerySnapshot favoritesResult = await FirebaseFirestore.instance
        .collectionGroup('favorites')
        .where('userId', isEqualTo: user!.id)
        .get();
    final List<DocumentSnapshot> queryFavorites = favoritesResult.docs;

    QuerySnapshot favoriteNews = await FirebaseFirestore.instance
        .collection('favoriteNews')
        .where('userId', isEqualTo: user!.id)
        .get();
    final List<DocumentSnapshot> queryArticles = favoriteNews.docs;
    setState(() {
      favoritesCount = queryFavorites.length;
      articlesCount = queryArticles.length;
      this.contentLoading = false;
    });

    for (int i = 0; i < queryFavorites.length; i++) {
      DocumentSnapshot queryFavorite =
          await queryFavorites[i].reference.parent.parent!.get();
      Map<String, dynamic> favorite =
          queryFavorite.data() as Map<String, dynamic>;

      DocumentSnapshot queryFavoriteUser =
          await queryFavorite.reference.parent.parent!.get();
      Map<String, dynamic> favoriteUser =
          queryFavoriteUser.data() as Map<String, dynamic>;

      favorite['id'] = queryFavorite.id;
      favorite['userId'] = queryFavoriteUser.id;
      favorite['isFavorite'] = false;
      favorite['isFavoriteLoading'] = false;
      favorite['userPhotoUrl'] = favoriteUser['photoUrl'];
      favorite['userFullName'] =
          "${favoriteUser['firstName']} ${favoriteUser['lastName']}";
      favorite['documentSnapshot'] = queryFavorite;
      favorite['types'] = jsonEncode(favorite['types']);

      PostModel.Post favoriteModel = PostModel.Post.fromJson(favorite);
      newFavorites.add(favoriteModel);
    }
    newFavorites.sort((a, b) {
      return b.timestamp.compareTo(a.timestamp);
    });
    setState(() {
      favorites = newFavorites;
    });

    // Favorite Articles
    List favoriteArticles = [];
    for (int i = 0; i < queryArticles.length; i++) {
      Map<String, dynamic> article =
          queryArticles[i].data() as Map<String, dynamic>;
      article['id'] = queryArticles[i].id;
      favoriteArticles.add(article);
    }
    favoriteArticles.sort((a, b) {
      return int.parse(b['timestamp']).compareTo(int.parse(a['timestamp']));
    });

    setState(() {
      articles = favoriteArticles;
    });

    getPostFavorites();
  }

  getPostFavorites() async {
    if (widget.userId == currentUserId || widget.userId == null) {
      favorites.forEach((post) {
        post.documentSnapshot.reference
            .collection('favorites')
            .where('userId', isEqualTo: currentUserId)
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
      });
    } else {
      posts.forEach((post) {
        post.documentSnapshot.reference
            .collection('favorites')
            .where('userId', isEqualTo: currentUserId)
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
      });
    }
  }

  Widget profileInfo() {
    if (prefs == null) return Container();
    return ChangeNotifierProvider.value(
      value: user,
      child: Consumer<UserModel.User>(
        builder: (context, value, child) {
          return Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Column(
              children: [
                Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    CircleAvatar(
                      radius: 61,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.3),
                      child: (user!.photoUrl != null)
                          ? CircleAvatar(
                              radius: 60.0,
                              backgroundImage:
                                  CachedNetworkImageProvider(user!.photoUrl!),
                            )
                          : CircleAvatar(
                              radius: 60.0,
                              backgroundImage:
                                  AssetImage('assets/images/logo.png'),
                            ),
                    ),
                    user!.id == currentUserId
                        ? Container(
                            height: 0.0,
                          )
                        : onlineStatus()
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 20.0, bottom: 5.0),
                  child: Text(
                    "${user!.firstName} ${user!.lastName}",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
                  ),
                ),
                Text(
                  user!.email!,
                  style: TextStyle(
                      fontSize: 14.0, color: Theme.of(context).primaryColor),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  StreamBuilder<DocumentSnapshot> onlineStatus() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.id)
          .snapshots(),
      builder: (context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData && snapshot.data!.data()!['isOnline'] == true) {
          return Positioned(
            bottom: 8.0,
            right: 8.0,
            child: Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                  color: Color(0XFF27AE60),
                  border: Border.all(color: Colors.white, width: 2.5),
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

  Widget reports() {
    Widget reports = Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0),
      margin: EdgeInsets.only(top: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: () => {
                  setState(() => {contentType = 'posts'})
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      color: contentType == 'posts'
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(50.0)),
                  child: Icon(
                    FontAwesomeIcons.thLarge,
                    size: 20.0,
                    color: contentType == 'posts'
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0, bottom: 8.0),
                child: Text(
                  posts.length.toString(),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24.0),
                ),
              ),
              Text(
                'Posts',
                style: TextStyle(fontSize: 14.0, color: Colors.black54),
              )
            ],
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => {
                  setState(() => {contentType = 'favorites'})
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      color: contentType == 'favorites'
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(50.0)),
                  child: Icon(
                    FontAwesomeIcons.solidHeart,
                    size: 20.0,
                    color: contentType == 'favorites'
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0, bottom: 8.0),
                child: Text(
                  favoritesCount.toString(),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24.0),
                ),
              ),
              Text(
                'Favorites',
                style: TextStyle(fontSize: 14.0, color: Colors.black54),
              )
            ],
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => {
                  setState(() => {contentType = 'articles'})
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      color: contentType == 'articles'
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(50.0)),
                  child: Icon(
                    FontAwesomeIcons.solidBookmark,
                    size: 20.0,
                    color: contentType == 'articles'
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0, bottom: 8.0),
                child: Text(
                  articlesCount.toString(),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24.0),
                ),
              ),
              Text(
                'Articles',
                style: TextStyle(fontSize: 14.0, color: Colors.black54),
              )
            ],
          ),
        ],
      ),
    );
    return reports;
  }

  Widget renderContent() {
    late Widget content;
    switch (contentType) {
      case 'posts':
        content = renderPosts();
        break;
      case 'favorites':
        content = renderFavorites();
        break;
      case 'articles':
        content = renderArticles();
        break;
    }
    return content;
  }

  Widget renderArticles() {
    if (articles.length == 0) {
      return Container(
        margin: EdgeInsets.only(top: 100.0),
        child: Text('No articles',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0, color: Colors.black54)),
      );
    }
    return Container(
      margin: EdgeInsets.only(top: 15.0),
      child: ListView.builder(
          itemCount: articles.length,
          primary: false,
          shrinkWrap: true,
          itemBuilder: (BuildContext ctxt, int index) {
            return buildNewsItem(index);
          }),
    );
  }

  String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    return htmlText.replaceAll(exp, '');
  }

  Widget buildNewsItem(index) {
    Uri source = Uri.parse(articles[index]['url']);
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: InkWell(
          onTap: () {
            try {
              launch(articles[index]['url']);
            } catch (e) {}
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          child: articles[index]['photoUrl'] != null
                              ? CachedNetworkImage(
                                  height: 200.0,
                                  width: MediaQuery.of(context).size.width,
                                  imageUrl: articles[index]['photoUrl'],
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                        height: 20.0,
                                        width: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        )),
                                  ),
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/placeholder.png',
                                  height: 200,
                                  width: MediaQuery.of(context).size.width,
                                  fit: BoxFit.cover,
                                  //color: Colors.black,
                                ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.transparent, Colors.black45],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                  blurRadius: 4.0,
                                ),
                              ]),
                        ),
                        currentUserId == user!.id || widget.userId == null
                            ? Positioned(
                                top: -5,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: IconButton(
                                    onPressed: () {
                                      toggleFavorite(index);
                                    },
                                    splashRadius: 20.0,
                                    icon: Icon(
                                      Ionicons.bookmark,
                                      color: Colors.red,
                                      size: 25.0,
                                    ),
                                  ),
                                ))
                            : Container(
                                height: 0.0,
                              ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: 15.0, right: 15.0, bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              articles[index]['title'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: TextStyle(
                                  height: 1.2,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Text(
                              articles[index]['pubDate'],
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.20,
                                  color: Colors.black54),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              articles[index]['description'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: TextStyle(fontSize: 17, height: 1.35),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15.0),
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      text: TextSpan(
                                        children: [
                                          WidgetSpan(
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 5.0),
                                              child: Transform(
                                                transform:
                                                    Matrix4.translationValues(
                                                        0.0, 2.0, 0.0),
                                                child: Icon(
                                                    Ionicons.link_outline,
                                                    size: 20.0,
                                                    color: Colors.black38),
                                              ),
                                            ),
                                          ),
                                          TextSpan(
                                            text: source.host
                                                .replaceAll('www.', ''),
                                            style: TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                                fontFamily: 'Raleway'),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  toggleFavorite(index) {
    CollectionReference favoriteNews =
        FirebaseFirestore.instance.collection('favoriteNews');
    favoriteNews.doc(articles[index]['id']).delete();
    setState(() {
      articles.removeAt(index);
      articlesCount--;
    });
  }

  String parseTimestamp(timestamp) {
    final f = DateFormat('MMMM dd, y hh:mm a');
    return f.format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
  }

  Widget implodeTags(List tags) {
    return Text(tags.reduce((value, element) => '#' + value + ' #' + element));
  }

  Widget renderFavorites() {
    if (favorites.length == 0) {
      return Container(
        margin: EdgeInsets.only(top: 100.0),
        child: Text('No favorites',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0, color: Colors.black54)),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 20.0),
      child: GridView.builder(
        gridDelegate:
            new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        primary: false,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildItem(favorites[index]);
        },
        itemCount: favorites.length,
      ),
    );
  }

  Widget renderPosts() {
    if (posts.length == 0) {
      return Container(
        margin: EdgeInsets.only(top: 100.0),
        child: Text('No posts',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0, color: Colors.black54)),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 20.0),
      child: GridView.builder(
        gridDelegate:
            new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        primary: false,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildItem(posts[index]);
        },
        itemCount: posts.length,
      ),
    );
  }

  Widget buildItem(PostModel.Post post) {
    return Padding(
      padding: EdgeInsets.all(1.0),
      child: GestureDetector(
        onTap: () => goToPost(post),
        child: CachedNetworkImage(
          imageUrl: post.images![0],
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  goToPost(PostModel.Post post) async {
    PostModel.Post? postData = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Post(
                post: post,
              )),
    );
    if (postData != null &&
        user!.id == currentUserId &&
        !postData.isFavorite!) {
      int index = favorites.indexWhere((element) => element.id == postData.id);
      if (index > -1) {
        setState(() {
          favorites.removeAt(index);
          favoritesCount--;
        });
      }
    }
  }

  goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => UserSettings(
                user: user,
              ),
          fullscreenDialog: true),
    );
  }

  goToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => HelpScreen(), fullscreenDialog: true),
    );
  }

  getConversation() async {
    if (currentUserId == user!.id) return;
    Conversation getConversation = Conversation.fromJson({
      'id': null,
      'userId': user!.id,
      'userFullName': '${user!.firstName} ${user!.lastName}',
      'userPhotoUrl': user!.photoUrl,
      'lastMessageId': null,
      'lastMessage': null,
      'lastMessageIsRead': false,
      'lastMessageTimestamp': null,
    });

    List userIds = [currentUserId, widget.userId];
    QuerySnapshot<Map<String, dynamic>> conversationResult =
        await FirebaseFirestore.instance.collection('conversations').get();

    final List<DocumentSnapshot<Map<String, dynamic>>> queryConversations =
        conversationResult.docs;
    Function deepEq = const DeepCollectionEquality.unordered().equals;
    for (DocumentSnapshot<Map<String, dynamic>> element in queryConversations) {
      List? queryUserIds = element.data()!['userIds'];
      if (queryUserIds != null &&
          deepEq(userIds, List.from(element.data()!['userIds']))) {
        getConversation.documentSnapshot = element;
        getConversation.id = element.id;
        break;
      }
    }
    setState(() {
      conversation = getConversation;
    });
  }

  goToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Messages(
                conversation: conversation,
              )),
    );
  }

  void logout() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'isOnline': false, 'deviceToken': ''});
    FirebaseAuth.instance.signOut().then((value) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false);
    });
  }
}
