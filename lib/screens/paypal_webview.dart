import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:CityLoads/helpers/paypal_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebView extends StatefulWidget {
  @override
  _PayPalWebViewState createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  String? checkoutUrl;
  String? executeUrl;
  String? accessToken;
  PaypalServices services = PaypalServices();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late WebViewController _webViewController;
  String? paypalClientId;
  String? paypalSecretKey;
  String returnURL = 'return.example.com';
  String cancelURL = 'cancel.example.com';
  String? chargeAmount;
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
    String? totalAmount = chargeAmount;
    String? subTotalAmount = chargeAmount;
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
      ..loadRequest(Uri.parse(checkoutUrl!))
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
    getPaypalCredentials();

    super.initState();
  }

  Future getPaypalCredentials() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> _paypalKeys =
          await DbFirestore().getKeys();
      paypalClientId = _paypalKeys.data()!['paypal_client_id'];
      paypalSecretKey = _paypalKeys.data()!['paypal_secret_key'];

      DocumentSnapshot<Map<String, dynamic>> _paypalCharge =
          await DbFirestore().getPaypalCharge();

      chargeAmount = _paypalCharge.data()!['charge'];

      accessToken =
          await services.getAccessToken(paypalClientId!, paypalSecretKey!);
      final transactions = getOrderParams();
      final res = await services.createPaypalPayment(transactions, accessToken);
      if (res != null) {
        checkoutUrl = res["approvalUrl"];
        executeUrl = res["executeUrl"];
      }
      print(checkoutUrl);
    } catch (e) {
      print('exception: ' + e.toString());
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
    instantiateWebViewController();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
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
