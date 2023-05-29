import 'dart:ui';

import 'package:CityLoads/helpers/countries_list.dart';
import 'package:CityLoads/models/country.dart';
import 'package:CityLoads/screens/home.dart';
import 'package:CityLoads/screens/loader.dart';
import 'package:CityLoads/screens/cities.dart';
import 'package:azlistview/azlistview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../models/post.dart' as PostModel;
import 'dart:io';

class Countries extends StatefulWidget {
  @override
  _CountriesState createState() => _CountriesState();
}

class _CountriesState extends State<Countries> {
  Map<String, dynamic> apiResult;
  List<DocumentSnapshot> queryPosts;
  List searchResultWithImage = [];
  List<CountryInfo> countryLists = [];
  TextEditingController searchBox = TextEditingController();
  List<Map<String, dynamic>> _countriesFlag = [];
  bool loading = true;
  bool toSearch = false;
  @override
  void initState() {
    super.initState();
    getCountryList();
    getCountries();
  }

  PanelController _panelController = PanelController();

  void searchCountry(String search) {
    searchResultWithImage.clear();
    if (search.isNotEmpty) {
      _countriesFlag.forEach((country) {
        if (country['countryName']
            .contains(RegExp(search, caseSensitive: false))) {
          searchResultWithImage.add(country);
        }
      });

      setState(() {});
    }
  }

  void getCountryList() async {
    apiResult = await CountryListApi()
        .getCountryList('https://countriesnow.space/api/v0.1/countries/iso');

    for (Map<String, dynamic> country in apiResult['data']) {
      countryLists.add(CountryInfo.fromJson(country));
    }
    _handleList(countryLists);

    getPosts();
  }

  void _handleList(List<CountryInfo> list) {
    if (list.isEmpty) return;
    for (int i = 0, length = list.length; i < length; i++) {
      String pinyin = PinyinHelper.getPinyinE(list[i].name);
      String tag = pinyin.substring(0, 1).toUpperCase();
      list[i].namePinyin = pinyin;
      if (RegExp("[A-Z]").hasMatch(tag)) {
        list[i].tagIndex = tag;
      } else {
        list[i].tagIndex = "#";
      }
    }
    SuspensionUtil.sortListBySuspensionTag(countryLists);
    SuspensionUtil.setShowSuspensionStatus(countryLists);
  }

  getCountries() async {
    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('settings/countries/countryList')
          .orderBy('index', descending: false)
          .get();
      for (int i = 0; i < result.docs.length; i++) {
        dynamic _country = result.docs[i].data();
        _country['documentId'] = result.docs[i].id;
        _countriesFlag.add(_country);
      }
    } catch (e) {
      print(e);
    }
  }

  getPosts() async {
    QuerySnapshot result =
        await FirebaseFirestore.instance.collectionGroup('posts').get();
    queryPosts = result.docs;
    getPostsByCountryInGrid();
    setState(() {
      loading = false;
    });
  }

  getPostsByCountryInGrid() async {
    for (Map<String, dynamic> country in _countriesFlag) {
      country['cities'] = getPostsByCountry(country['iso2Code']);
    }
  }

  List<dynamic> getPostsByCountry(String countryCode) {
    List countryPosts = [];
    for (int i = 0; i < queryPosts.length; i++) {
      Map<String, dynamic> post = queryPosts[i].data();
      if (post['mappedAddress'] != null) {
        if (post['mappedAddress']['isoCountryCode'] == countryCode) {
          countryPosts.add(post['mappedAddress']);
        }
      }
    }

    return countryPosts ?? [];
  }

  String panelAction = 'See all countries';
  // double bodyHeight = MediaQuery.of(context).size.height -
  //     Scaffold.of(context).appBarMaxHeight;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: false,
        title: Text(
          'DISCOVER',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 26.0,
              fontFamily: 'TexGyreAdventor'),
        ),
        actions: [
          toSearch
              ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: TextField(
                      controller: searchBox,
                      onChanged: (value) {
                        searchCountry(value);
                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'TexGyreAdventor',
                      ),
                      decoration: InputDecoration(
                          prefix: SvgPicture.asset(
                            'assets/icons/search.svg',
                            height: 15,
                            width: 15,
                          ),
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontFamily: 'TexGyreAdventor',
                          ),
                          hintText: 'Search',
                          suffix: GestureDetector(
                              child: SvgPicture.asset(
                                'assets/icons/close.svg',
                                height: 20,
                                width: 20,
                              ),
                              onTap: () {
                                searchBox.clear();
                                setState(() {
                                  toSearch = false;
                                });
                              })),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () => setState(() => toSearch = true),
                  splashRadius: 20.0,
                  icon: SvgPicture.asset(
                    'assets/icons/search.svg',
                    height: 20,
                    width: 20,
                  ))
        ],
      ),
      body: Container(
        child: SlidingUpPanel(
          controller: _panelController,
          parallaxEnabled: true,
          minHeight: 40,
          onPanelSlide: (pos) {},
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            topLeft: Radius.circular(15),
          ),
          onPanelClosed: () {
            setState(() {
              panelAction = 'View all countries';
            });
          },
          onPanelOpened: () {
            setState(() {
              panelAction = 'Hide';
            });
          },
          panel: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15),
                  ),
                ),
                alignment: Alignment.center,
                child: GestureDetector(
                    onTap: () {
                      if (_panelController.isPanelOpen) {
                        _panelController.close();
                      } else {
                        _panelController.open();
                      }
                      setState(() {});
                    },
                    child: Text(
                      panelAction,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    )),
              ),
              Expanded(
                child: AzListView(
                  data: countryLists,
                  itemCount: countryLists.length,
                  padding: const EdgeInsets.all(10),
                  indexBarItemHeight: 15,
                  itemBuilder: (context, index) {
                    List<CountryInfo> country = countryLists;
                    return GestureDetector(
                      onTap: () {
                        List cities = getPostsByCountry(country[index].iso2);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Home(
                              selection: 1,
                              cities: cities,
                              isoCode: country[index].iso2,
                              countryName: country[index].name,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5,
                        ),
                        child: Text(
                          country[index].name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                  physics: BouncingScrollPhysics(),
                  indexBarOptions: IndexBarOptions(
                    needRebuild: true,
                    ignoreDragCancel: true,
                    textStyle: TextStyle(fontSize: 10),
                    downTextStyle: TextStyle(fontSize: 10, color: Colors.white),
                    downItemDecoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey[500]),
                    indexHintWidth: 120 / 2,
                    indexHintHeight: 100 / 2,
                    indexHintDecoration: BoxDecoration(),
                    indexHintAlignment: Alignment.centerRight,
                    indexHintChildAlignment: Alignment(-0.25, 0.0),
                    indexHintOffset: Offset(-20, 0),
                  ),
                ),
              ),
            ],
          ),
          body: loading
              ? Loader()
              : Container(
                  padding: EdgeInsets.only(bottom: Platform.isIOS ? 250 : 200),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: searchBox.text.isEmpty
                        ? _countriesFlag.length
                        : searchResultWithImage.length,
                    itemBuilder: (BuildContext context, index) {
                      List<dynamic> country = searchBox.text.isEmpty
                          ? _countriesFlag
                          : searchResultWithImage;
                      List cityy = [];
                      for (Map<String, dynamic> city in country[index]
                          ['cities']) {
                        cityy.add(city['postalCode']);
                      }
                      String cityCount =
                          cityy.toSet().toList().length.toString();
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => Home(
                                    selection: 1,
                                    cities: country[index]['cities'],
                                    isoCode: country[index]['iso2Code'],
                                    countryName: country[index]['countryName'],
                                  )));
                        },
                        child: CountryCard(
                            flagUrl: country[index]['flagUrl'],
                            countryName:
                                country[index]['countryName'].toUpperCase(),
                            cityCount: cityCount),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class CountryCard extends StatelessWidget {
  final String flagUrl;
  final String countryName;
  final String cityCount;
  const CountryCard({
    Key key,
    this.flagUrl,
    this.countryName,
    this.cityCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: flagUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 0),
                  blurRadius: 0.0,
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      countryName,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.2,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'TexGyreAdventor',
                      ),
                    ),
                  ),
                ),
                FittedBox(
                  child: Text(
                    '$cityCount Cities',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontFamily: 'TexGyreAdventor',
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
