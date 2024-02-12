import 'dart:async';

import 'package:collection/collection.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:fcm_admin_portal/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/fcm/v1.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:retry/retry.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:geocode/geocode.dart' as gc;
import 'package:http/http.dart' as http;

class ViewModel {
  static List<String> get scopes => <String>[
        FirebaseCloudMessagingApi.firebaseMessagingScope,
        FirestoreApi.datastoreScope,
        Oauth2Api.openidScope,
        Oauth2Api.userinfoEmailScope,
        Oauth2Api.userinfoProfileScope,
      ];

  static String get clientId => '1711820455-j1b8sa87l5p5gkvebt4vv8r6ppnagq7s.apps.googleusercontent.com';
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    clientId: clientId,
    forceCodeForRefreshToken: true,
    scopes: scopes,
  );
  static ViewModel? _singleton;
  static ViewModel get singleton => _singleton!;

  static late StreamSubscription sub;

  static void init() async {
    if (_singleton != null) return;

    _singleton = ViewModel._();

    final signInResult = await _googleSignIn.signInSilently(
      suppressErrors: false,
    );

    final authentication = await signInResult?.authentication;

    await _googleSignIn.requestScopes(scopes);
    singleton.authClient.value = await _googleSignIn.authenticatedClient();

    _singleton?.account.value = signInResult;

    sub = _googleSignIn.onCurrentUserChanged.listen((event) {
      _singleton?.account.value = event;
    });
    singleton.loadMedicationResponses();
    singleton.loadDevices();
  }

  ViewModel._();

  final medicationResponse = signal<Iterable<(MedicationResponse, Signal<AsyncState<FullAddress>?>)>>([]);
  late final mapAddressResolutions = signalContainer(
    ((double lat, double long) point) {
      final a = futureSignal(
        () => _loadAddress(
          lat: point.$1,
          long: point.$2,
        ),
      );
      return a;
    },
    cache: true,
  );
  final devices = listSignal<Device>([]);

  final authClient = signal<auth.AuthClient?>(null);
  final account = signal<GoogleSignInAccount?>(null);

  void loadMedicationResponses() async {
    final api = FirestoreApi(authClient.value!);

    final result = await api.projects.databases.documents.listDocuments(
      'projects/epicarenet-5e2bb/databases/(default)/documents',
      'tmp_medication_notification_response',
      orderBy: 'timestamp desc',
    );
    final map = result.documents?.map((e) {
      if (e.fields == null) return null;

      final med = MedicationResponse.fromValueMap(e.fields!);
      if (med.long == null || med.lat == null) {
        return (
          med,
          signal<AsyncState<FullAddress>?>(null),
        );
      }
      final s = mapAddressResolutions((med.lat!.toDouble(), med.long!.toDouble()));

      return (med, s);
    }).whereNotNull();

    medicationResponse.value = map ?? [];
  }

  Future<FullAddress> _loadAddress({
    required double long,
    required double lat,
  }) async {
    final fullAddress = await retry(
      () => http.get(
        Uri.https(
          'api.bigdatacloud.net',
          '/data/reverse-geocode-client',
          {
            'latitude': lat.toString(),
            'longitude': long.toString(),
            'localityLanguage': 'en',
          },
        ),
      ),
    );

    final address = Address.fromJson(fullAddress.body);

    return FullAddress(
      city: address.city,
      country: address.countryName,
      fullAddress: '${address.countryName} - ${address.city} - ${address.locality}',
    );
  }

  Future<FullAddress> _loadAddressNew({
    required double long,
    required double lat,
  }) async {
    final geocode = gc.GeoCode(apiKey: '261759532030236250355x83384');

    final fullAddress = await retry(
      () => geocode.reverseGeocoding(
        latitude: lat,
        longitude: long,
      ),
    );

    return FullAddress(
      country: fullAddress.countryName,
      city: fullAddress.city,
      fullAddress: fullAddress.streetAddress,
    );
  }

  Future<void> loadDevices() async {
    final api = FirestoreApi(authClient.value!);

    final result = await api.projects.databases.documents.listDocuments(
      'projects/epicarenet-5e2bb/databases/(default)/documents',
      'tmp_device_info',
    );
    final map =
        result.documents?.map((e) => e.fields == null ? null : Device.fromValueMap(e.fields!)).whereNotNull().toList();

    devices.value = map ?? [];
  }

  void reset() {}
  void signOut() {
    _googleSignIn.signOut().then((value) {});
  }

  void dispose() {
    _singleton = null;
  }
}

class FullAddress {
  final String? country;
  final String? city;
  final String? fullAddress;

  FullAddress({
    this.country,
    this.city,
    this.fullAddress,
  });
}
