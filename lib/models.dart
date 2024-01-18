import 'dart:convert';

import 'package:googleapis/firestore/v1.dart';

class Device {
  final String? token;
  final String? model;
  final String? name;
  final String? appId;

  Device({
    this.token,
    this.model,
    this.name,
    this.appId,
  });
  static Device fromValueMap(Map<String, Value> data) {
    return Device(
      token: data['token']?.stringValue,
      model: data['model']?.stringValue,
      name: data['name']?.stringValue,
      appId: data['app_id']?.stringValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Device && other.token == token;
  }

  @override
  int get hashCode {
    return token.hashCode ^ model.hashCode ^ name.hashCode ^ appId.hashCode;
  }
}

class MedicationResponse {
  final String name;
  final String dose;
  final String action;
  final num? long;
  final num? lat;
  final DateTime timestamp;

  MedicationResponse({
    required this.name,
    required this.dose,
    required this.action,
    this.long,
    this.lat,
    required this.timestamp,
  });

  static MedicationResponse fromValueMap(Map<String, Value> data) {
    return MedicationResponse(
      name: data['name']!.stringValue!,
      dose: data['dose']!.stringValue!,
      action: data['action']!.stringValue!,
      long: data['long']?.doubleValue,
      lat: data['lat']?.doubleValue,
      timestamp: DateTime.parse(data['timestamp']!.timestampValue!),
    );
  }
}

/*
{
  "message": {
    "token": "eZ9qN3UHRqW8ky4BOLv7dP:APA91bHJKYo_zfAaGkN5tEtoHKzXPcLcsCYcbLFSS1qx_uml9ldXV68FAg308Ng-0GyF2pn9Ddt6rMqcCB3L-3lxjPTdYcUUMIPqRMZ3VeeodLkr40_DHYUr_50vZ5Nq3aGCcK_1_XbD",
    "notification": {
      "title": "Hello",
      "body": "My Body"
    },
    "apns": {
      "payload": {
        "aps": {
          "alert": {
            "title": "Caraflam",
            "body": "2 Pills"
          },
          "interruption-level": "time-sensitive",
          "sound": "default",
          "content-available": 1,
          "category": "medication_reminder"
        }
      },
      "headers": {
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-topic": "com.novelaneuro.HomeHub"
      }
    },
    "data": {
      "eventTypeId": "2",
      "medication_id": "1",
      "time": "12:31:00",
      "title": "Dymmy Cataflam",
      "message": "3 Pills",
      "reminder_id": "224"
    }
  }
}
*/

class Address {
  final double? latitude;
  final String? lookupSource;
  final double? longitude;
  final String? localityLanguageRequested;
  final String? continent;
  final String? continentCode;
  final String? countryName;
  final String? countryCode;
  final String? principalSubdivision;
  final String? principalSubdivisionCode;
  final String? city;
  final String? locality;
  final String? postcode;
  final String? plusCode;
  final Fips? fips;
  final LocalityInfo? localityInfo;

  Address({
    this.latitude,
    this.lookupSource,
    this.longitude,
    this.localityLanguageRequested,
    this.continent,
    this.continentCode,
    this.countryName,
    this.countryCode,
    this.principalSubdivision,
    this.principalSubdivisionCode,
    this.city,
    this.locality,
    this.postcode,
    this.plusCode,
    this.fips,
    this.localityInfo,
  });

  factory Address.fromJson(String str) => Address.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Address.fromMap(Map<String, dynamic> json) => Address(
        latitude: json["latitude"]?.toDouble(),
        lookupSource: json["lookupSource"],
        longitude: json["longitude"]?.toDouble(),
        localityLanguageRequested: json["localityLanguageRequested"],
        continent: json["continent"],
        continentCode: json["continentCode"],
        countryName: json["countryName"],
        countryCode: json["countryCode"],
        principalSubdivision: json["principalSubdivision"],
        principalSubdivisionCode: json["principalSubdivisionCode"],
        city: json["city"],
        locality: json["locality"],
        postcode: json["postcode"],
        plusCode: json["plusCode"],
        fips: json["fips"] == null ? null : Fips.fromMap(json["fips"]),
        localityInfo: json["localityInfo"] == null ? null : LocalityInfo.fromMap(json["localityInfo"]),
      );

  Map<String, dynamic> toMap() => {
        "latitude": latitude,
        "lookupSource": lookupSource,
        "longitude": longitude,
        "localityLanguageRequested": localityLanguageRequested,
        "continent": continent,
        "continentCode": continentCode,
        "countryName": countryName,
        "countryCode": countryCode,
        "principalSubdivision": principalSubdivision,
        "principalSubdivisionCode": principalSubdivisionCode,
        "city": city,
        "locality": locality,
        "postcode": postcode,
        "plusCode": plusCode,
        "fips": fips?.toMap(),
        "localityInfo": localityInfo?.toMap(),
      };
}

class Fips {
  final String? state;
  final String? county;
  final String? countySubdivision;
  final String? place;

  Fips({
    this.state,
    this.county,
    this.countySubdivision,
    this.place,
  });

  factory Fips.fromJson(String str) => Fips.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Fips.fromMap(Map<String, dynamic> json) => Fips(
        state: json["state"],
        county: json["county"],
        countySubdivision: json["countySubdivision"],
        place: json["place"],
      );

  Map<String, dynamic> toMap() => {
        "state": state,
        "county": county,
        "countySubdivision": countySubdivision,
        "place": place,
      };
}

class LocalityInfo {
  final List<Ative>? administrative;
  final List<Ative>? informative;

  LocalityInfo({
    this.administrative,
    this.informative,
  });

  factory LocalityInfo.fromJson(String str) => LocalityInfo.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory LocalityInfo.fromMap(Map<String, dynamic> json) => LocalityInfo(
        administrative: json["administrative"] == null
            ? []
            : List<Ative>.from(json["administrative"]!.map((x) => Ative.fromMap(x))),
        informative:
            json["informative"] == null ? [] : List<Ative>.from(json["informative"]!.map((x) => Ative.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "administrative": administrative == null ? [] : List<dynamic>.from(administrative!.map((x) => x.toMap())),
        "informative": informative == null ? [] : List<dynamic>.from(informative!.map((x) => x.toMap())),
      };
}

class Ative {
  final String? name;
  final String? description;
  final String? isoName;
  final int? order;
  final int? adminLevel;
  final String? isoCode;
  final String? wikidataId;
  final int? geonameId;

  Ative({
    this.name,
    this.description,
    this.isoName,
    this.order,
    this.adminLevel,
    this.isoCode,
    this.wikidataId,
    this.geonameId,
  });

  factory Ative.fromJson(String str) => Ative.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Ative.fromMap(Map<String, dynamic> json) => Ative(
        name: json["name"],
        description: json["description"],
        isoName: json["isoName"],
        order: json["order"],
        adminLevel: json["adminLevel"],
        isoCode: json["isoCode"],
        wikidataId: json["wikidataId"],
        geonameId: json["geonameId"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "description": description,
        "isoName": isoName,
        "order": order,
        "adminLevel": adminLevel,
        "isoCode": isoCode,
        "wikidataId": wikidataId,
        "geonameId": geonameId,
      };
}
