import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:ionicons/ionicons.dart';

class Terms extends StatelessWidget {
  final String terms;

  const Terms({Key key, this.terms}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
                splashRadius: 20.0,
                icon: Icon(
                  Ionicons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop());
          },
        ),
        title: Text('TERMS',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 22.0)),
      ),
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
            child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: HtmlWidget(
              '''$terms''',
              // webView: false,
            ),
          ),
        ));
      }),
    );
  }
}
