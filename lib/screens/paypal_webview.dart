import 'dart:io';
import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:CityLoads/helpers/paypal_services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebView extends StatefulWidget {
  @override
  _PayPalWebViewState createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  String checkoutUrl;
  String executeUrl;
  String accessToken;
  PaypalServices services = PaypalServices();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  WebViewController _webViewController;
  String paypalClientId;
  String paypalSecretKey;
  String returnURL = 'return.example.com';
  String cancelURL = 'cancel.example.com';
  String chargeAmount;
  Map<dynamic, dynamic> defaultCurrency = {
    "symbol": "USD ",
    "decimalDigits": 2,
    "symbolBeforeTheNumber": true,
    "currency": "USD"
  };

  Map<String, dynamic> getOrderParams() {
    List items = [
      {
        "name": 'itemName',
        "quantity": 1,
        "price": chargeAmount,
        "currency": defaultCurrency["currency"]
      }
    ];
    // checkout invoice details
    String totalAmount = chargeAmount;
    String subTotalAmount = chargeAmount;
    String shippingCost = '0';
    int shippingDiscountCost = 0;

    Map<String, dynamic> temp = {
      "intent": "sale",
      "payer": {"payment_method": "paypal"},
      "transactions": [
        {
          "amount": {
            "total": totalAmount,
            "currency": defaultCurrency["currency"],
            "details": {
              "subtotal": subTotalAmount,
              "shipping": shippingCost,
              "shipping_discount": ((-1.0) * shippingDiscountCost).toString()
            }
          },
          "description": "The payment transaction description.",
          "payment_options": {
            "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
          },
          "item_list": {
            "items": items,
            // "shipping_address": {
            //   "recipient_name": userFirstName + " " + userLastName,
            //   "line1": addressStreet,
            //   "line2": "",
            //   "city": addressCity,
            //   "country_code": addressCountry,
            //   "postal_code": addressZipCode,
            //   "phone": addressPhoneNumber,
            //   "state": addressState
            // },
          }
        }
      ],
      "note_to_payer": "Contact us for any questions on your order.",
      "redirect_urls": {
        "return_url": returnURL,
        "cancel_url": cancelURL,
      }
    };
    return temp;
  }

  instantiateWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(checkoutUrl))
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.contains(returnURL)) {
            final uri = Uri.parse(request.url);
            final payerID = uri.queryParameters['PayerID'];
            if (payerID != null) {
              services
                  .executePayment(executeUrl, payerID, accessToken)
                  .then((id) {
                Navigator.pop(context, true);
              });
            }
          }
          if (request.url.contains(cancelURL)) {
            Navigator.pop(context, false);
          }
          return NavigationDecision.navigate;
        },
      ));
  }

  @override
  void initState() {
    // if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    instantiateWebViewController();
    Future.delayed(Duration.zero, () async {
      try {
        await DbFirestore().getKeys().then(
          (_keys) {
            paypalClientId = _keys.data()['paypal_client_id'];
            paypalSecretKey = _keys.data()['paypal_secret_key'];
          },
        );
        await DbFirestore().getPaypalCharge().then(
          (_keys) {
            chargeAmount = _keys.data()['charge'];
          },
        );
        accessToken =
            await services.getAccessToken(paypalClientId, paypalSecretKey);
        final transactions = getOrderParams();
        final res =
            await services.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          setState(() {
            checkoutUrl = res["approvalUrl"];
            executeUrl = res["executeUrl"];
          });
        }
      } catch (e) {
        print('exception: ' + e.message);
        Fluttertoast.showToast(
          msg: e.toString(),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: WebViewWidget(
          controller: _webViewController,
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: Center(child: Container(child: CircularProgressIndicator())),
      );
    }
  }
}
