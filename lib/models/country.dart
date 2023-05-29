import 'dart:convert';

import 'package:azlistview/azlistview.dart';

class CountryInfo extends ISuspensionBean {
  String name;
  String iso2;
  String iso3;
  String tagIndex;
  String namePinyin;
  String firstLetter;

  CountryInfo({
    this.name,
    this.iso2,
    this.iso3,
    this.tagIndex,
    this.namePinyin,
    this.firstLetter,
  });

  CountryInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        iso2 = json['Iso2'],
        iso3 = json['Iso3'],
        firstLetter = json['firstLetter'];

  Map<String, dynamic> toJson() => {'name': name, 'Iso2': iso2, 'Iso3': iso3};

  @override
  String getSuspensionTag() => tagIndex;

  @override
  String toString() => json.encode(this);
}
