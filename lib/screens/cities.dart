import 'package:CityLoads/screens/feed.dart';
import 'package:CityLoads/screens/home.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class Cities extends StatefulWidget {
  final List<Map<String, dynamic>> cities;
  final String? countryName;
  final String? countryCode;
  const Cities(
      {Key? key, required this.cities, this.countryCode, this.countryName})
      : super(key: key);

  @override
  _StatesState createState() => _StatesState();
}

class _StatesState extends State<Cities> {
  List cities = [];
  List cityy = [];
  bool loading = true;
  @override
  void initState() {
    // TODO: implement initState
    //print(widget.cities);
    getCities();
    super.initState();
  }

  getCities() async {
    for (Map<String, dynamic>? city in widget.cities) {
      city!['cityImageUrl'] = await getCityImage(city['postalCode']);
      cityy.add(city['postalCode']);
    }
    cities = cityy.toSet().toList();
    setState(() {
      loading = false;
    });
  }

  getCityImage(String? postalCode) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> result = await FirebaseFirestore
          .instance
          .collection('settings/countries/cityList')
          .doc(postalCode)
          .get();
      if (result.data() != null) {
        return result.data()!['cityImageUrl'];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Ionicons.chevron_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context)),
        // automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        title: Text(
          widget.countryName!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 23.0,
            fontFamily: 'TexGyreAdventor',
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () => null,
        //     splashRadius: 20.0,
        //     icon: Icon(
        //       Ionicons.search_outline,
        //       color: Colors.black,
        //       size: 25.0,
        //     ),
        //   )
        // ],
      ),
      body: loading
          ? Center(
              child: Text(
              'Please wait...',
              style: TextStyle(fontSize: 20),
            ))
          : cities.length == 0
              ? Center(
                  child: Text(
                  'No posts yet in this country.',
                  style: TextStyle(fontSize: 20),
                ))
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width / 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 5,
                  ),
                  itemCount: cities.length,
                  itemBuilder: (BuildContext context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (context) => Home(
                                        city: widget.cities[index]['locality'],
                                        isoCode: widget.countryCode,
                                        selection: 2,
                                      ))),
                          child: CityCard(
                            cities: widget.cities[index]['locality'],
                            cityImage: widget.cities[index]['cityImageUrl'],
                            properties: cityy
                                .where((element) => element == cities[index])
                                .length
                                .toString(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CityCard extends StatelessWidget {
  final String? cityImage;
  final String? cities;
  final String? properties;
  const CityCard({
    Key? key,
    this.cities,
    this.properties,
    this.cityImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        children: [
          Center(
            child: cityImage != null
                ? CachedNetworkImage(
                    imageUrl: cityImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.asset(
                    'assets/images/logo_login.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black12],
                ),
                //   borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 0),
                    blurRadius: 0.0,
                  ),
                ]),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cities!.toUpperCase(),
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.2,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'TexGyreAdventor',
                  ),
                ),
                FittedBox(
                  child: Text(
                    '$properties Properties',
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 13,
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
