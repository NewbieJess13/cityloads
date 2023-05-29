import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:credit_card_validate/credit_card_validate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';
import './loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Payment extends StatefulWidget {
  final Map<String, dynamic> creditCard;
  const Payment({Key key, this.creditCard}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  Map<String, dynamic> creditCard;
  String userId;
  final cardholderNameFocus = FocusNode();
  final cardNumberFocus = FocusNode();
  final cvvFocus = FocusNode();
  final dateFocus = FocusNode();
  String cardholderName = '';
  String cardNumber = '';
  String cvv = '';
  String date = '';
  TextEditingController cardHolderNameController = TextEditingController();
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController cvvController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  String cardType = '';
  bool isLoading = false;
  String loadingText = '';
  SharedPreferences prefs;

  @override
  initState() {
    super.initState();
    creditCard = widget.creditCard;
    if (creditCard != null) {
      setState(() {
        cardholderName = creditCard['cardholderName'];
        cardNumber = creditCard['cardNumber'];
        cvv = creditCard['cvv'];
        date = '${creditCard['month']}/${creditCard['year']}';
        cardType = creditCard['cardType'];
        cardHolderNameController.text = cardholderName;
        cardNumberController.text = cardNumber;
        cvvController.text = cvv;
        dateController.text = date;
      });
    }
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
                icon: Icon(
                  Ionicons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop()),
            backgroundColor: Colors.white,
            elevation: 0.0,
            title: Text('PAYMENT',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 22.0)),
          ),
          body: LayoutBuilder(builder:
              (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight),
                    child: Column(children: [
                      Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    Container(
                                      child: Transform(
                                        transform: Matrix4.translationValues(
                                            0, -24.0, 0.0),
                                        child: Text(
                                          'Select a payment method for future in app purchases',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            height: 1.5,
                                            color: Colors.black38,
                                            fontSize: 17.0,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(20.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black12)),
                                        child: Opacity(
                                          opacity:
                                              cardType == 'visa' ? 1.0 : 0.35,
                                          child: SvgPicture.asset(
                                            'assets/images/visa.svg',
                                            height: 25.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                        margin:
                                            EdgeInsets.only(left: 6, right: 6)),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(13.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black12)),
                                        child: Opacity(
                                          opacity: cardType == 'master_card'
                                              ? 1.0
                                              : 0.35,
                                          child: SvgPicture.asset(
                                            'assets/images/mastercard.svg',
                                            height: 40.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                        margin:
                                            EdgeInsets.only(left: 6, right: 6)),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(13.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black12)),
                                        child: Opacity(
                                          opacity: 0.35,
                                          child: SvgPicture.asset(
                                            'assets/images/paypal.svg',
                                            height: 40.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                    margin: EdgeInsets.only(top: 20.0),
                                    child: TextField(
                                        controller: cardHolderNameController,
                                        focusNode: cardholderNameFocus,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18.0),
                                        decoration: InputDecoration(
                                            labelStyle: TextStyle(
                                                fontWeight: FontWeight.w300),
                                            labelText: 'Cardholder name'),
                                        onChanged: (String value) {
                                          cardholderName = value.trim();
                                        })),
                                Container(
                                    margin: EdgeInsets.only(top: 15.0),
                                    child: TextField(
                                        controller: cardNumberController,
                                        focusNode: cardNumberFocus,
                                        maxLength: 16,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18.0),
                                        decoration: InputDecoration(
                                            counterText: "",
                                            labelStyle: TextStyle(
                                                fontWeight: FontWeight.w300),
                                            labelText: 'Card Number'),
                                        onChanged: (String value) {
                                          cardNumber = value.trim();
                                          setState(() {
                                            cardType = CreditCardValidator
                                                .identifyCardBrand(cardNumber);
                                          });
                                        })),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              controller: cvvController,
                                              keyboardType:
                                                  TextInputType.number,
                                              focusNode: cvvFocus,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'CVV'),
                                              onChanged: (String value) {
                                                cvv = value.trim();
                                              })),
                                    ),
                                    Expanded(
                                      child: Container(
                                          margin: EdgeInsets.only(
                                              left: 15.0, top: 15.0),
                                          child: TextField(
                                              controller: dateController,
                                              focusNode: dateFocus,
                                              readOnly: true,
                                              onTap: () => {openDatePicker()},
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'MM/YYYY'),
                                              onChanged: (String value) {
                                                date = value.trim();
                                              })),
                                    ),
                                  ],
                                ),
                              ]))
                    ])));
          }),
          bottomNavigationBar: BottomAppBar(
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
                  child: Text(
                      'Credt card payment may take up to 24h to be processed.',
                      style: TextStyle(color: Colors.red, fontSize: 16.0)),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0, right: 5.0),
                        child: Material(
                            child: InkWell(
                                onTap: () => {Navigator.pop(context)},
                                child: Container(
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.black12)),
                                  child: Container(
                                      margin: EdgeInsets.only(
                                          top: 17.0, bottom: 17.0),
                                      child: Text('CANCEL',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .primaryColor))),
                                ))),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 5.0, right: 15.0),
                        child: Material(
                            color: Theme.of(context).primaryColor,
                            child: InkWell(
                                onTap: () => {validate()},
                                child: Container(
                                    margin: EdgeInsets.only(
                                        top: 17.0, bottom: 17.0),
                                    child: Text('SAVE CARD',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white))))),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        isLoading
            ? Loader(
                text: loadingText,
              )
            : Container(
                height: 0.0,
              )
      ],
    );
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  openDatePicker() {
    DateFormat formatter = DateFormat('MM/yyyy');
    DateTime initialDate = DateTime.now();
    if (date.isNotEmpty) {
      List dateParts = date.split('/');
      if (dateParts.length != 2) return;
      initialDate = DateTime(int.parse(dateParts[1]), int.parse(dateParts[0]));
    }
    DatePicker.showDatePicker(context,
        initialDateTime: initialDate,
        maxDateTime: DateTime.now().add(Duration(days: 3650)),
        minDateTime: DateTime.now(),
        dateFormat: 'MM/yyyy', onConfirm: (newDate, data) {
      if (newDate != null) {
        setState(() => {date = formatter.format(newDate)});
        dateController.text = date;
      }
    });
  }

  validate() {
    if (cardholderName.isNotEmpty &&
        cardNumber.isNotEmpty &&
        cvv.isNotEmpty &&
        CreditCardValidator.isCreditCardValid(cardNumber: cardNumber) &&
        date.isNotEmpty) {
      List dateParts = date.split('/');
      Map<String, dynamic> cardData = {
        'cardholderName': cardholderName,
        'cardNumber': cardNumber,
        'cvv': cvv,
        'year': dateParts[1],
        'month': dateParts[0],
        'cardType': cardType
      };
      createCard(cardData);
    } else {
      if (cardholderName.isEmpty) {
        cardholderNameFocus.requestFocus();
      } else if (cardNumber.isEmpty) {
        cardNumberFocus.requestFocus();
      } else if (!CreditCardValidator.isCreditCardValid(
          cardNumber: cardNumber)) {
        cardNumberFocus.requestFocus();
        Fluttertoast.showToast(
            msg: "Invalid card number.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (cvv.isEmpty) {
        cvvFocus.requestFocus();
      } else if (date.isEmpty) {
        openDatePicker();
        dateFocus.requestFocus();
      }
    }
  }

  createCard(Map<String, dynamic> cardData) async {
    setState(() {
      loadingText = 'Saving card..';
      isLoading = true;
    });

    Map<String, dynamic> newCardPostData = {
      'cardholderName': cardData['cardholderName'],
      'cardNumber': cardData['cardNumber'],
      'cvv': cardData['cvv'],
      'year': cardData['year'],
      'month': cardData['month'],
      'cardType': cardData['cardType']
    };
    if (creditCard != null) {
      await FirebaseFirestore.instance
          .collection('creditCards')
          .doc(creditCard['id'])
          .update(newCardPostData);
      newCardPostData['id'] = creditCard['id'];
      Navigator.of(context).pop(newCardPostData);
    } else {
      newCardPostData['userId'] = userId;
      CollectionReference creditCards =
          FirebaseFirestore.instance.collection('creditCards');
      DocumentReference card = await creditCards.add(newCardPostData);
      DocumentSnapshot newCard = await card.get();
      Map<String, dynamic> newCardData = newCard.data();
      newCardData['id'] = newCard.id;
      Navigator.of(context).pop(newCardData);
    }
  }
}
