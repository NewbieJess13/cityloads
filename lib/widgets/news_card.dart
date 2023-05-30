import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/web_analyzer.dart';
import '../models/article.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';
import 'package:jiffy/jiffy.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class NewsCard extends StatefulWidget {
  final Article? article;
  final String? userId;

  const NewsCard({Key? key, this.article, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  Article? article;
  String? formattedDate;
  late Uri source;

  @override
  void initState() {
    super.initState();
    article = widget.article;
    // getInfo();
    getFavorite();

    final pubDate = parseHttpDate(article!.pubDate!);
    formattedDate = Jiffy.parseFromDateTime(pubDate).yMMMMd;
    source = Uri.parse(article!.url!);
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
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Stack(
          children: [
            InkWell(
              onTap: () {
                try {
                  launchUrl(Uri.parse(article!.url!));
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
                              child: article!.photoUrl == null
                                  ? Image.asset(
                                      'assets/images/google_news_512.png',
                                      height: 200,
                                      width: MediaQuery.of(context).size.width,
                                      fit: BoxFit.cover,
                                      //color: Colors.black,
                                    )
                                  : CachedNetworkImage(
                                      height: 200.0,
                                      width: MediaQuery.of(context).size.width,
                                      imageUrl: article!.photoUrl!,
                                      placeholder: (context, url) => Center(
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
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                        'assets/images/placeholder.png',
                                        height: 200,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        fit: BoxFit.cover,
                                        //color: Colors.black,
                                      ),
                                    ),
                            ),
                            Container(
                              height: 200,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black45
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 2),
                                      blurRadius: 4.0,
                                    ),
                                  ]),
                            ),
                            Positioned(
                                top: -5,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: ChangeNotifierProvider.value(
                                      value: article,
                                      child: Consumer<Article>(
                                          builder: (context, value, child) {
                                        return article!.isFavoriteLoading ==
                                                true
                                            ? Padding(
                                                padding: EdgeInsets.only(
                                                    right: 15.0, top: 15.0),
                                                child: SizedBox(
                                                    width: 20.0,
                                                    height: 20.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 1,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    )),
                                              )
                                            : IconButton(
                                                onPressed: () {
                                                  toggleFavorite();
                                                },
                                                splashRadius: 20.0,
                                                icon: Icon(
                                                  article!.favoriteNewsId !=
                                                          null
                                                      ? Ionicons.bookmark
                                                      : Ionicons
                                                          .bookmark_outline,
                                                  color:
                                                      article!.favoriteNewsId !=
                                                              null
                                                          ? Colors.red
                                                          : Colors.white,
                                                  size: 25.0,
                                                ),
                                              );
                                      })),
                                )),
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
                                child: ChangeNotifierProvider.value(
                                    value: article,
                                    child: Consumer<Article>(
                                        builder: (context, value, child) {
                                      return Text(
                                        article!.title!,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        style: TextStyle(
                                            height: 1.2,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.w700),
                                      );
                                    })),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 5.0),
                                child: Text(
                                  formattedDate.toString(),
                                  style: TextStyle(
                                      fontSize: 15,
                                      height: 1.20,
                                      color: Colors.black54),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 15.0),
                                child: ChangeNotifierProvider.value(
                                    value: article,
                                    child: Consumer<Article>(
                                        builder: (context, value, child) {
                                      return Text(
                                        article!.description!,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        style: TextStyle(
                                            fontSize: 17, height: 1.35),
                                      );
                                    })),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  padding: EdgeInsets.only(
                                                      right: 5.0),
                                                  child: Transform(
                                                    transform: Matrix4
                                                        .translationValues(
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
            // Positioned.fill(
            //   child: BackdropFilter(
            //     filter: new ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            //     child: new Container(
            //       decoration: BoxDecoration(
            //           color: Colors.grey.shade200.withOpacity(0.5)),
            //       child: Center(
            //         child: Center(
            //           child: SizedBox(
            //               height: 20.0,
            //               width: 20.0,
            //               child: CircularProgressIndicator(
            //                 strokeWidth: 1,
            //                 valueColor: AlwaysStoppedAnimation<Color>(
            //                     Theme.of(context).primaryColor),
            //               )),
            //         ),
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  // getInfo() async {
  //   // InfoBase? webInfo = await WebAnalyzer.getInfo(article!.url);

  //   if (webInfo is WebInfo) {
  //     article!.photoUrl = webInfo.image;
  //     // if (webInfo.title != null &&
  //     //     !webInfo.title
  //     //         .contains(RegExp(r'Request unsuccessful', caseSensitive: false)))
  //     //   article.title = webInfo.title;
  //     // if (webInfo.description != null)
  //     //   article.description = webInfo.description;
  //     // article.update();
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future getFavorite() async {
    QuerySnapshot favoriteNews = await FirebaseFirestore.instance
        .collection('favoriteNews')
        .where('url', isEqualTo: article!.url)
        .where('userId', isEqualTo: widget.userId)
        .limit(1)
        .get();

    if (favoriteNews.docs.length > 0) {
      article!.favoriteNewsId = favoriteNews.docs[0].id;
      article!.update();
    }
  }

  toggleFavorite() async {
    article!.isFavoriteLoading = true;
    article!.update();
    CollectionReference favoriteNews =
        FirebaseFirestore.instance.collection('favoriteNews');
    String? favoriteNewsId;
    if (article!.favoriteNewsId == null) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      DocumentReference newFavoriteNews = await favoriteNews.add({
        'userId': widget.userId,
        'url': article!.url,
        'title': article!.title,
        'description': article!.description,
        'photoUrl': article!.photoUrl,
        'pubDate': article!.pubDate,
        'timestamp': timestamp
      });
      favoriteNewsId = newFavoriteNews.id;
    } else {
      favoriteNewsId = null;
      await favoriteNews.doc(article!.favoriteNewsId).delete();
    }

    article!.favoriteNewsId = favoriteNewsId;
    article!.isFavoriteLoading = false;
    article!.update();
  }
}
