import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> linkPreview(String url) async {
  var client = http.Client();
  return await client.get(Uri.parse(url)).then((response) {
    return response.body;
  }).then((bodyString) {
    print(bodyString);
    return jsonDecode(bodyString);
  });
}
