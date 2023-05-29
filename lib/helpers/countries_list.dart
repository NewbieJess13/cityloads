import 'dart:convert';

import 'package:http/http.dart' as http;

class CountryListApi {
  Future<Map<String, dynamic>> getCountryList(String url) async {
    var client = http.Client();
    return await client.get(Uri.parse(url)).then((response) {
      return response.body;
    }).then((bodyString) {
      //  print(bodyString);
      return jsonDecode(bodyString);
    });
  }
}
