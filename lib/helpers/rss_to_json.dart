import 'dart:convert';

import 'package:xml2json/xml2json.dart';
import 'package:http/http.dart' as http;

Future<List> rssToJson(String url) async {
  var client = http.Client();
  final myTranformer = Xml2Json();
  Uri uri = Uri.parse(url);
  return await client.get(uri).then((response) {
    return response.body;
  }).then((bodyString) {
    myTranformer.parse(bodyString);
    var json = myTranformer.toParker();
    return jsonDecode(json)['rss']['channel']['item'];
  });
}
