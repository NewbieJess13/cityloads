import 'package:flutter/material.dart';
//import './login.dart';

class Loader extends StatefulWidget {
  final String text;

  const Loader({Key key, this.text}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            height: 30.0,
            width: 30.0,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            )),
        textContent()
      ],
    )));
  }

  Widget textContent() {
    Widget textContent = Container(height: 0.0);
    if (widget.text != null) {
      textContent = Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17.0),
        ),
      );
    }

    return textContent;
  }
}
