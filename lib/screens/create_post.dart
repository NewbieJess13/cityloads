import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:CityLoads/screens/paypal_webview.dart';
import 'package:awesome_dropdown/awesome_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import './loader.dart';
import 'package:flutter_tags_x/flutter_tags_x.dart';
// import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/number_picker.dart';
import '../widgets/image_preview.dart';
import './payment.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class CreatePost extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final picker = ImagePicker();
  bool isLoading = false;
  FocusNode titleFocus = FocusNode();
  FocusNode yearFocus = FocusNode();
  FocusNode priceFocus = FocusNode();
  FocusNode locationFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode sizeFocus = FocusNode();
  String title = '';
  String year = '';
  String price = '';
  String? location = '';
  Map geoAddress = Map();
  String description = '';
  String size = '';
  int bedrooms = 0;
  int baths = 0;
  int floors = 0;
  String selectedCurrency = 'USD';
  bool? parking = false;
  bool? maid = false;
  String availableFor = 'rent';
  String rentPeriod = 'annual';
  String interior = 'furnished';
  List? types;
  double lat = 0;
  double long = 0;
  String? gmaps_api_key = '';

  final GlobalKey<TagsState> _tagStateKey = GlobalKey<TagsState>();
  ScrollController scrollController = ScrollController();
  TextEditingController yearController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool _isBackPressedOrTouchedOutSide = false,
      _isDropDownOpened = false,
      _isPanDown = false;
  List<Widget> imagePreviews = [];
  List images = [];
  late SharedPreferences prefs;
  Map<String, dynamic>? creditCard;
  @override
  initState() {
    super.initState();
    types = [];
    setState(() {
      imagePreviews.add(Padding(
        padding: EdgeInsets.all(3.0),
        child: InkWell(
          onTap: () => {pickImage()},
          child: Container(
            decoration:
                BoxDecoration(border: Border.all(color: Colors.black12)),
            child: Center(
              child: Icon(FontAwesomeIcons.plus),
            ),
          ),
        ),
      ));
    });
    getPreferences();
    getApiKeys();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeFocus,
      onPanDown: (focus) {
        _isPanDown = true;
        _removeFocus();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  centerTitle: false,
                  title: Text('CREATE A POST',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18.0)),
                  actions: [
                    IconButton(
                      onPressed: () => {Navigator.pop(context)},
                      splashRadius: 20.0,
                      icon: Icon(
                        FontAwesomeIcons.times,
                        color: Colors.black,
                        size: 24.0,
                      ),
                    )
                  ],
                ),
                body: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: viewportConstraints.maxHeight),
                      child: GestureDetector(
                        onTap: () => {hideKeyboard()},
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                  child: TextField(
                                      focusNode: titleFocus,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.0),
                                      decoration: InputDecoration(
                                          labelStyle: TextStyle(
                                              fontWeight: FontWeight.w300),
                                          labelText: 'Title'),
                                      onChanged: (String value) {
                                        this.title = value.trim();
                                      })),
                              Container(
                                  margin: EdgeInsets.only(top: 15.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          margin: EdgeInsets.only(right: 5.0),
                                          child: TextField(
                                            keyboardType:
                                                TextInputType.datetime,
                                            focusNode: yearFocus,
                                            onTap: () => {openDatePicker()},
                                            readOnly: true,
                                            controller: yearController,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16.0),
                                            decoration: InputDecoration(
                                                labelStyle: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w300),
                                                labelText: 'Year built'),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 8,
                                        child: Container(
                                          margin: EdgeInsets.only(left: 5.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: AwesomeDropDown(
                                                  padding: 8,
                                                  isPanDown: true,
                                                  isBackPressedOrTouchedOutSide:
                                                      _isBackPressedOrTouchedOutSide,
                                                  dropDownList: [
                                                    'USD',
                                                    'EUR',
                                                    'GBP',
                                                    'CNY',
                                                    'JPY',
                                                    'AED',
                                                    'SAR'
                                                  ],
                                                  onDropDownItemClick:
                                                      (selectedItem) {
                                                    selectedCurrency =
                                                        selectedItem;
                                                    print(selectedItem);
                                                  },
                                                  dropStateChanged: (isOpened) {
                                                    _isDropDownOpened =
                                                        isOpened;
                                                    if (!isOpened) {
                                                      _isBackPressedOrTouchedOutSide =
                                                          false;
                                                    }
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: TextField(
                                                    keyboardType: TextInputType
                                                        .numberWithOptions(
                                                            decimal: true),
                                                    focusNode: priceFocus,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16.0),
                                                    decoration: InputDecoration(
                                                        labelStyle: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w300),
                                                        labelText: 'Price'),
                                                    onChanged: (String value) {
                                                      this.price = value.trim();
                                                    }),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                              Container(
                                  margin: EdgeInsets.only(top: 15.0),
                                  child: TextField(
                                      focusNode: locationFocus,
                                      onTap: () {
                                        openMapPicker();
                                      },
                                      readOnly: true,
                                      controller: locationController,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.0),
                                      decoration: InputDecoration(
                                          suffixIcon: SvgPicture.asset(
                                            'assets/icons/location.svg',
                                            height: 10,
                                            width: 10,
                                            fit: BoxFit.none,
                                          ),
                                          labelStyle: TextStyle(
                                              fontWeight: FontWeight.w300),
                                          labelText: 'Location'),
                                      onChanged: (String value) {
                                        this.location = value.trim();
                                      })),
                              Container(
                                  margin: EdgeInsets.only(top: 15.0),
                                  child: TextField(
                                      focusNode: descriptionFocus,
                                      minLines: 1,
                                      maxLines: 10,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.0),
                                      decoration: InputDecoration(
                                          labelStyle: TextStyle(
                                              fontWeight: FontWeight.w300),
                                          labelText: 'Description'),
                                      onChanged: (String value) {
                                        this.description = value.trim();
                                      })),
                              Container(
                                  margin:
                                      EdgeInsets.only(top: 30.0, bottom: 15.0),
                                  child: Text(
                                    'IMAGES',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  )),
                              GridView.count(
                                primary: false,
                                shrinkWrap: true,
                                crossAxisCount: 3,
                                children: [...imagePreviews],
                              ),
                              Container(
                                  margin: EdgeInsets.only(bottom: 15.0),
                                  child: Text(
                                    'TYPE',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  )),
                              typeTags(),
                              Container(
                                  margin: EdgeInsets.only(top: 15.0),
                                  child: TextField(
                                      keyboardType: TextInputType.number,
                                      focusNode: sizeFocus,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.0),
                                      decoration: InputDecoration(
                                          labelStyle: TextStyle(
                                              fontWeight: FontWeight.w300),
                                          labelText: 'Size in SQFT'),
                                      onChanged: (String value) {
                                        this.size = value.trim();
                                      })),
                              Container(
                                  margin:
                                      EdgeInsets.only(top: 30.0, bottom: 15.0),
                                  child: Text(
                                    'LIVING SPACE',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0),
                                  )),
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
                                            child: SvgPicture.asset(
                                              'assets/icons/bedroom.svg',
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            )),
                                      ),
                                      Text(
                                        'Bedroom',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black54),
                                      )
                                    ],
                                  ),
                                  NumberPicker(
                                    value: bedrooms,
                                    onChange: (newValue) => {
                                      setState(() => {bedrooms = newValue})
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
                                              child: SvgPicture.asset(
                                                'assets/icons/bath.svg',
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
                                        ),
                                        Text(
                                          'Baths',
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    NumberPicker(
                                      value: baths,
                                      onChange: (newValue) => {
                                        setState(() => {baths = newValue})
                                      },
                                    )
                                  ],
                                ),
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
                                              FontAwesomeIcons.layerGroup,
                                              size: 16.0,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Floors',
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    NumberPicker(
                                      value: floors,
                                      onChange: (newValue) => {
                                        setState(() => {floors = newValue})
                                      },
                                    )
                                  ],
                                ),
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
                                              child: SvgPicture.asset(
                                                'assets/icons/parking.svg',
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
                                        ),
                                        Text(
                                          'Car Parking',
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 125.0,
                                      height: 24.0,
                                      child: Checkbox(
                                        value: this.parking,
                                        onChanged: (newValue) {
                                          setState(() {
                                            this.parking = newValue;
                                          });
                                        },
                                      ),
                                    ),
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
                                              child: SvgPicture.asset(
                                                'assets/icons/maid.svg',
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
                                        ),
                                        Text(
                                          'Maid Room',
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 125.0,
                                      height: 24.0,
                                      child: Checkbox(
                                        value: this.maid,
                                        onChanged: (newValue) {
                                          setState(() {
                                            this.maid = newValue;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...availableForSelect(),
                              ...rentSelect(),
                              ...interiorSelect(),
                              // ...paymentDetails(),
                              bottomButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              child: isLoading
                  ? Loader(
                      text: 'Creating Post..',
                    )
                  : Container(),
            )
          ],
        ),
      ),
    );
  }

  hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _removeFocus() {
    if (_isDropDownOpened) {
      setState(() {
        _isBackPressedOrTouchedOutSide = true;
      });
    }
  }

  List<Widget> availableForSelect() {
    return [
      Container(
          margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
          child: Text(
            'AVAILABLE FOR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
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
                    color: availableFor == 'rent'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('RENT',
                      style: TextStyle(
                          color: availableFor == 'rent'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () => {
                    setState(() => {availableFor = 'rent'})
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: availableFor == 'sale'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('SALE',
                      style: TextStyle(
                          color: availableFor == 'sale'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () => {
                    setState(() => {availableFor = 'sale'})
                  },
                ),
              ),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> rentSelect() {
    return [
      Opacity(
        opacity: availableFor == 'rent' ? 1.0 : 0.25,
        child: Container(
            margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
            child: Text(
              'RENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            )),
      ),
      AbsorbPointer(
        absorbing: availableFor == 'rent' ? false : true,
        child: Opacity(
          opacity: availableFor == 'rent' ? 1.0 : 0.25,
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
                        color: rentPeriod == 'annual'
                            ? Theme.of(context).primaryColor
                            : Colors.white),
                    child: ElevatedButton(
                      child: Text('ANNUAL',
                          style: TextStyle(
                              color: rentPeriod == 'annual'
                                  ? Colors.white
                                  : Colors.black54)),
                      onPressed: () => {
                        setState(() => {rentPeriod = 'annual'})
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: rentPeriod == 'monthly'
                            ? Theme.of(context).primaryColor
                            : Colors.white),
                    child: ElevatedButton(
                      child: Text('MONTHLY',
                          style: TextStyle(
                              color: rentPeriod == 'monthly'
                                  ? Colors.white
                                  : Colors.black54)),
                      onPressed: () => {
                        setState(() => {rentPeriod = 'monthly'})
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

  List<Widget> interiorSelect() {
    return [
      Container(
          margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
          child: Text(
            'INTERIOR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
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
                    color: interior == 'furnished'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('FURNISHED',
                      style: TextStyle(
                          color: interior == 'furnished'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () => {
                    setState(() => {interior = 'furnished'})
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: interior == 'not_furnished'
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                child: ElevatedButton(
                  child: Text('NOT FURNISHED',
                      style: TextStyle(
                          color: interior == 'not_furnished'
                              ? Colors.white
                              : Colors.black54)),
                  onPressed: () => {
                    setState(() => {interior = 'not_furnished'})
                  },
                ),
              ),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> paymentDetails() {
    List<Widget> paymentDetails = [
      Container(
          margin: EdgeInsets.only(top: 30.0, bottom: 15.0),
          child: Text(
            'PAYMENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ))
    ];
    if (creditCard == null) {
      paymentDetails.add(Container(
          child: ButtonTheme(
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor:
                Theme.of(context).primaryColor.withOpacity(0.5),
            backgroundColor: Theme.of(context).primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          ),
          child: Text('SELECT PAYMENT', style: TextStyle(color: Colors.white)),
          onPressed: () => {openPayment()},
        ),
      )));
    } else {
      paymentDetails.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'Price for each new post is',
                  style: TextStyle(
                      fontFamily: 'RaleWay',
                      color: Colors.black45,
                      fontSize: 17.0)),
              TextSpan(
                  text: '\$5.00',
                  style: TextStyle(
                      fontFamily: 'RaleWay',
                      color: Theme.of(context).primaryColor,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700)),
              TextSpan(
                  text: '. Please select payment method.',
                  style: TextStyle(
                      fontFamily: 'RaleWay',
                      color: Colors.black45,
                      fontSize: 17.0)),
            ]),
          ),
          Padding(
            padding: EdgeInsets.only(top: 25.0),
            child: Text(
              'Saved payment',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 10.0),
            child: InkWell(
              onTap: () => {openPayment()},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '************' +
                          creditCard!['cardNumber']
                              .substring(creditCard!['cardNumber'].length - 4),
                      style: TextStyle(
                          fontSize: 22.0, fontWeight: FontWeight.w700),
                    ),
                  ),
                  cardIcon(creditCard!['cardType'])
                ],
              ),
            ),
          )
        ],
      ));
    }

    return paymentDetails;
  }

  Widget cardIcon(String? cardType) {
    Widget cardIcon = Container();
    switch (cardType) {
      case 'visa':
        cardIcon = SvgPicture.asset(
          'assets/images/visa.svg',
          height: 15.0,
        );
        break;
      case 'master_card':
        cardIcon = SvgPicture.asset(
          'assets/images/mastercard.svg',
          height: 15.0,
        );
        break;
    }

    return Row(
      children: [
        cardIcon,
        Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Icon(
            FontAwesomeIcons.chevronRight,
            size: 20.0,
            color: Colors.black38,
          ),
        )
      ],
    );
  }

  openPayment() async {
    Map<String, dynamic>? creditCardData = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Payment(
                creditCard: creditCard,
              ),
          fullscreenDialog: true),
    );
    if (creditCardData != null) {
      setState(() {
        creditCard = creditCardData;
      });
    }
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    getCreditCard();
  }

  getApiKeys() async {
    await DbFirestore().getKeys().then((_keys) {
      gmaps_api_key = _keys.data()!['gmaps_api_key'];
    });
  }

  getCreditCard() async {
    QuerySnapshot creditCardResult = await FirebaseFirestore.instance
        .collection('creditCards')
        .where('userId', isEqualTo: prefs.getString('userId'))
        .limit(1)
        .get();
    List<QueryDocumentSnapshot> creditCards = creditCardResult.docs;
    if (creditCards.length > 0) {
      setState(() {
        creditCard = creditCards[0].data() as Map<String, dynamic>?;
        creditCard!['id'] = creditCards[0].id;
      });
    }
  }

  Widget bottomButtons() {
    return SafeArea(
        child: Container(
          margin: EdgeInsets.only(top: 40.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Material(
                    child: InkWell(
                        onTap: () => {Navigator.pop(context)},
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12)),
                          child: Container(
                              margin: EdgeInsets.only(top: 15.0, bottom: 15.0),
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
                        onTap: () => {validateForm()},
                        child: Container(
                            margin: EdgeInsets.only(top: 15.0, bottom: 15.0),
                            child: Text('CREATE POST',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white))))),
              ),
            ],
          ),
        ),
        top: false);
  }

  addImagePreview(File image) {
    Widget imagePreview = Container(
      height: 0.0,
    );
    imagePreview = ImagePreview(
      image: image,
      onRemove: () {
        setState(() {
          images.removeWhere((item) => item['image'] == image);
          imagePreviews.removeWhere((item) => item == imagePreview);
        });
      },
    );
    setState(() {
      imagePreviews.insert(0, imagePreview);
    });
  }

  Future pickImage() async {
    PermissionStatus permissionStatus;
    if (Platform.isAndroid) {
      permissionStatus = await Permission.storage.request();
    } else {
      permissionStatus = await Permission.photos.request();
    }
    if (permissionStatus.isPermanentlyDenied) {
      showAllowGalleryDialog();
      return;
    }

    if (permissionStatus.isGranted) {
      try {
        List<XFile> pickedImages =
            await picker.pickMultiImage(imageQuality: 80, maxWidth: 800);
        if (pickedImages != null) {
          for (var i = 0; i < pickedImages.length; i++) {
            images.insert(0, {'image': File(pickedImages[i].path)});
            addImagePreview(File(pickedImages[i].path));
          }

          setState(() {});
        }
      } catch (e) {}
    }
  }

  Widget typeTags() {
    return Tags(
      runSpacing: 5.0,
      runAlignment: WrapAlignment.spaceEvenly,
      key: _tagStateKey,
      textField: TagsTextField(
        autofocus: false,
        inputDecoration: InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.only(
            left: 10.0,
            right: 5.0,
            top: 13.0,
            bottom: 13.0,
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
        width: 130.0,
        hintText: 'Add New',
        hintTextColor: Colors.white.withOpacity(0.85),
        textStyle: TextStyle(fontSize: 16.0, color: Colors.white),
        onSubmitted: (String str) {
          setState(() {
            types!.addAll({
              {'title': str, 'active': true}
            });
          });
        },
      ),
      alignment: WrapAlignment.start,
      itemCount: types!.length, // required
      itemBuilder: (int index) {
        final item = types![index];

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
          textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          combine: ItemTagsCombine.withTextBefore,
          removeButton: ItemTagsRemoveButton(
            backgroundColor: Colors.white,
            color: Colors.black45,
            size: 20.0,
            onRemoved: () {
              setState(() {
                types!.removeAt(index);
              });
              return true;
            },
          ),
        );
      },
    );
  }

  openDatePicker() {
    DateFormat formatter = DateFormat('yyyy');
    DatePicker.showDatePicker(context,
        initialDateTime: (year != '')
            ? DateTime.parse(year + '-01-01 00:00:00')
            : DateTime.now(),
        maxDateTime: DateTime.now(),
        dateFormat: 'yyyy', onConfirm: (date, data) {
      if (date != null) {
        setState(() => {year = formatter.format(date)});
        yearController.text = year;
      }
    });
  }

  openMapPicker() async {
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted == false) {
      showAllowLocationDialog();
      return;
    }
    LatLng initialLocation = LatLng(lat, long);
    bool useCurrentLocation = (lat == 0 && long == 0);
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        enableDrag: true,
        builder: (BuildContext context) => Container(
              margin: EdgeInsets.only(top: 35.0),
              child: PlacePicker(
                apiKey: gmaps_api_key!,
                //Google Maps API key

                selectedPlaceWidgetBuilder:
                    (_, PickResult? selectedPlace, state, isSearchBarFocused) {
                  return isSearchBarFocused
                      ? Container()
                      : FloatingCard(
                          color: Colors.transparent,
                          bottomPosition: 30.0,
                          leftPosition: 0.0,
                          rightPosition: 0.0,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: state == SearchingState.Searching
                                  ? Center(
                                      child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: SizedBox(
                                          height: 20.0,
                                          width: 20.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1,
                                            valueColor: AlwaysStoppedAnimation<
                                                    Color>(
                                                Theme.of(context).primaryColor),
                                          )),
                                    ))
                                  : Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          Text(selectedPlace!.formattedAddress!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18.0)),
                                          Padding(
                                            padding: EdgeInsets.only(top: 10.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor),
                                              child: Text('Select',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16.0)),
                                              onPressed: () async {
                                                List<Placemark>
                                                    locationAddress =
                                                    await placemarkFromCoordinates(
                                                  selectedPlace
                                                      .geometry!.location.lat,
                                                  selectedPlace
                                                      .geometry!.location.lng,
                                                );

                                                geoAddress.addAll(
                                                    locationAddress[0]
                                                        .toJson());

                                                print(geoAddress);
                                                setState(() {
                                                  locationController.text =
                                                      selectedPlace
                                                          .formattedAddress!;
                                                  location = selectedPlace
                                                      .formattedAddress;
                                                  lat = selectedPlace
                                                      .geometry!.location.lat;
                                                  long = selectedPlace
                                                      .geometry!.location.lng;
                                                });
                                                Navigator.pop(context);
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        );
                },
                initialPosition: initialLocation,
                useCurrentLocation: useCurrentLocation,
                selectInitialPosition: true,
              ),
            ));
  }

  showAllowGalleryDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return SimpleDialog(
                titlePadding: EdgeInsets.only(top: 20.0),
                contentPadding: EdgeInsets.only(
                    top: 15.0, right: 15.0, bottom: 15.0, left: 15.0),
                children: [
                  Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              'Please allow CityLoads to access your media library from your settings.',
                              style: TextStyle(fontSize: 16.0, height: 1.35)),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Material(
                                child: InkWell(
                                    onTap: () =>
                                        {AppSettings.openAppSettings()},
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black12)),
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            top: 15.0, bottom: 15.0),
                                        child: Text(
                                          'OPEN SETTINGS',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ),
                                    ))),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Material(
                                child: InkWell(
                                    onTap: () => {Navigator.of(context).pop()},
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black12)),
                                      child: Container(
                                          margin: EdgeInsets.only(
                                              top: 15.0, bottom: 15.0),
                                          child: Text('CLOSE',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                    ))),
                          )
                        ],
                      ),
                    ],
                  )
                ],
              );
            }));
  }

  showAllowLocationDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SimpleDialog(
            titlePadding: EdgeInsets.only(top: 20.0),
            contentPadding: EdgeInsets.only(
                top: 15.0, right: 15.0, bottom: 15.0, left: 15.0),
            children: [
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          'Please allow CityLoads to access your location from your settings.',
                          style: TextStyle(fontSize: 16.0, height: 1.35)),
                      Padding(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Material(
                            child: InkWell(
                                onTap: () => {AppSettings.openAppSettings()},
                                child: Container(
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.black12)),
                                  child: Container(
                                      margin: EdgeInsets.only(
                                          top: 15.0, bottom: 15.0),
                                      child: Text('OPEN SETTINGS',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .primaryColor))),
                                ))),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Material(
                            child: InkWell(
                                onTap: () => {Navigator.of(context).pop()},
                                child: Container(
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.black12)),
                                  child: Container(
                                      margin: EdgeInsets.only(
                                          top: 15.0, bottom: 15.0),
                                      child: Text('CLOSE',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .primaryColor))),
                                ))),
                      )
                    ],
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  validateForm() {
    // createPost({null});
    if (title.isNotEmpty &&
        year.isNotEmpty &&
        price.isNotEmpty &&
        selectedCurrency.isNotEmpty &&
        location!.isNotEmpty &&
        description.isNotEmpty &&
        images.length > 0 &&
        size.isNotEmpty) {
      var postData = {
        'title': title,
        'year': year,
        'currency': selectedCurrency,
        'price': price,
        'location': location,
        'mappedAddress': geoAddress,
        'description': description,
        'images': images,
        'types': types,
        'size': size,
        'bedrooms': bedrooms,
        'baths': baths,
        'floors': floors,
        'parking': parking,
        'maid': maid,
        'availableFor': availableFor,
        'rentPeriod': rentPeriod,
        'interior': interior,
        'lat': lat,
        'long': long,
      };
      createPost(postData);
    } else {
      String errorMessage = '';
      if (title.isEmpty) {
        errorMessage = 'Title is required.';
        scrollController.animateTo(0.0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn);
        titleFocus.requestFocus();
      } else if (year.isEmpty) {
        errorMessage = 'Year built is required.';
        scrollController.animateTo(80.0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn);
        yearFocus.requestFocus();
      } else if (price.isEmpty) {
        errorMessage = 'Price is required.';
        priceFocus.requestFocus();
      } else if (location!.isEmpty) {
        errorMessage = 'Location is required.';
        locationFocus.requestFocus();
        scrollController.animateTo(120.0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn);
      } else if (description.isEmpty) {
        errorMessage = 'Description is required.';
        descriptionFocus.requestFocus();
      } else if (images.length == 0) {
        errorMessage = 'Please attach at least 1 image.';
        scrollController.animateTo(300.0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn);
      } else if (size.isEmpty) {
        errorMessage = 'Size is required.';
        sizeFocus.requestFocus();
      }
      // else if (creditCard == null) {
      //   errorMessage = 'Please add a payment method';
      // }

      Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  bool? paypalSuccess;
  Future createPost(postData) async {
    // hideKeyboard();

    // Paypal
    paypalSuccess = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PayPalWebView(),
      ),
    );
    if (paypalSuccess!) {
      setState(() => isLoading = true);
      List parsedTypes = [];
      for (int i = 0; i <= postData['types'].length - 1; i++) {
        parsedTypes.add(postData['types'][i]['title']);
      }
      List uploadedImages = [];
      List resizedImages = [];

      for (int i = 0; i <= postData['images'].length - 1; i++) {
        //File image = await resizeImage(postData['images'][i]['image']);
        File image = postData['images'][i]['image'];
        resizedImages.add(image);
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = timestamp +
            '-' +
            UniqueKey().toString().replaceAll('[#', '').replaceAll(']', '');
        Reference reference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = reference.putFile(image);
        TaskSnapshot storageTaskSnapshot =
            await uploadTask.whenComplete(() => null);
        print(storageTaskSnapshot.state);
        if (storageTaskSnapshot.state == TaskState.success) {
          String imageUrl = await storageTaskSnapshot.ref.getDownloadURL();
          uploadedImages.add(imageUrl);
        }
      }

      DocumentReference userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(prefs.getString('userId'));
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      print('hehe: $uploadedImages');
      await userReference.collection('posts').add({
        'title': postData['title'],
        'year': postData['year'],
        'currency': postData['currency'],
        'price': postData['price'],
        'location': postData['location'],
        'mappedAddress': geoAddress,
        'description': postData['description'],
        'images': uploadedImages,
        'types': parsedTypes,
        'size': postData['size'],
        'bedrooms': postData['bedrooms'],
        'baths': postData['baths'],
        'floors': postData['floors'],
        'parking': postData['parking'],
        'maid': postData['maid'],
        'availableFor': postData['availableFor'],
        'rentPeriod': postData['rentPeriod'],
        'interior': postData['interior'],
        'lat': postData['lat'],
        'long': postData['long'],
        'timestamp': timestamp
      });

      for (File image in resizedImages as Iterable<File>) {
        image.delete();
      }

      Fluttertoast.showToast(
        msg: 'Post created successfully.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.of(context).pop(true);
    }
  }
}
