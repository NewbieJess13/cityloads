import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/rss_to_json.dart';
import '../helpers/web_analyzer.dart';
import '../widgets/news_card.dart';
import '../models/article.dart';
import 'package:html/parser.dart';

class News extends StatefulWidget {
  // final String currentUserId;
  // News({Key key, @required this.currentUserId}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _NewsState();
}

class _NewsState extends State<News> {
  bool isLoading = true;
  String userId;
  SharedPreferences prefs;
  List news = [];
  String search = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getPreferences();
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: false,
        title: Text('LATEST NEWS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 26.0)),
        actions: [
          // IconButton(
          //   onPressed: () => {openSearch()},
          //   splashRadius: 20.0,
          //   icon: Icon(
          //     Ionicons.search_outline,
          //     color: Colors.black,
          //     size: 25.0,
          //   ),
          // )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'Searching for',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black54,
                                  fontFamily: 'Raleway')),
                          TextSpan(
                              text: ' $search',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway'))
                        ]),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0),
                        child: GestureDetector(
                          onTap: () {
                            searchController.text = '';
                            setState(() {
                              search = '';
                            });
                            getNews();
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  height: 0.0,
                ),
          Flexible(
            child: isLoading
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
                : news.length == 0
                    ? Center(
                        child: Text(
                        'No news found.',
                        style: TextStyle(fontSize: 17.0, color: Colors.black54),
                      ))
                    : ListView.builder(
                        itemCount: news.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return buildItem(index);
                        }),
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
    getNews();
  }

  getNews() async {
    String url = 'https://news.google.com/rss/search?q=real+estate&c=UAE';
    List newsRss = await rssToJson(url);
    List newsData = [];
    for (Map<String, dynamic> newsItem in newsRss) {
      final document = newsItem['description'];
      String description = removeAllHtmlTags(document);
      newsData.add({
        'title': newsItem['title'].toString().replaceAll('\\', ''),
        'url': newsItem['link'],
        'pubDate': newsItem['pubDate'],
        'description': description,
        'source': newsItem['source'],
      });
    }

    setState(() {
      news = newsData;
      isLoading = false;
    });
  }

  String removeAllHtmlTags(String htmlText) {
    var document = parse(htmlText);
    String parsedString = parse(document.body.text).documentElement.text;
    return parsedString.replaceAll('\\', '');
  }

  Widget buildItem(index) {
    Article article = Article.fromJson(news[index]);
    // return Container(
    //   child: Text(news[index]['title']),
    // );
    return NewsCard(article: article, userId: userId);
  }

  openSearch() {
    showModalBottomSheet(
        isScrollControlled: false,
        context: context,
        enableDrag: true,
        builder: (BuildContext context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    left: 15.0, right: 15.0, top: 15.0, bottom: 30.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextField(
                          autofocus: true,
                          controller: searchController,
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16.0),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: 'Search news...'),
                          onChanged: (String value) {
                            search = value.trim();
                          }),
                    ),
                    IconButton(
                      splashRadius: 20.0,
                      icon: Icon(
                        Ionicons.search_outline,
                        color: Colors.black,
                        size: 25.0,
                      ),
                      onPressed: () {
                        getNews();
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ),
              );
            }));
  }

  resetSearch([bool refresh]) {
    setState(() {
      search = '';
    });
    if (refresh == true) getNews();
  }
}
