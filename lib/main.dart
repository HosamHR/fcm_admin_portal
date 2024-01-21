import 'dart:async';
import 'dart:convert';
import 'dart:math';

// #docregion Import
import 'package:collection/collection.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:fcm_admin_portal/models.dart';
import 'package:fcm_admin_portal/sign_in_button.dart';
// #enddocregion Import
import 'package:flutter/material.dart' hide Notification;
import 'package:geocode/geocode.dart' as gc;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/fcm/v1.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

late final SharedPreferences sharedPreferences;
void main() async {
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Device> devices = [];
  Device? selectedDevice;
  String token = '';
  String title = '';
  String body = '';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    ViewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: getBody(),
        ),
      ),
    );
  }

  Widget getBody() {
    final account = ViewModel.singleton._account.watch(context);
    if (account == null) {
      return buildSignInButton();
    }
    return Builder(builder: (context) {
      final responses = ViewModel.singleton.medicationResponse.watch(context);

      return Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    ViewModel.singleton.signOut();
                  },
                  child: Text('Sign out'),
                ),
                Text(account.email),
                Text(account.displayName ?? 'No Name'),
                if (account.photoUrl != null) Image.network(account.photoUrl!),
                Builder(
                  builder: (context) {
                    final devices = ViewModel.singleton.devices.watch(context);
                    return DropdownButton(
                      value: selectedDevice,
                      itemHeight: 100,
                      items: devices
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                '${e.model}\n${e.name}\n${e.appId}',
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDevice = value;
                        });
                      },
                    );
                  },
                ),
                TextField(
                  onChanged: (value) {
                    title = value;
                  },
                  decoration: InputDecoration(
                    label: Text('Title'),
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    body = value;
                  },
                  decoration: InputDecoration(
                    label: Text('Body'),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final api = FirebaseCloudMessagingApi(ViewModel.singleton._authClient.value!);
                    try {
                      final result = await api.projects.messages.send(
                        SendMessageRequest(
                          message: Message(
                            token: selectedDevice?.token,
                            android: AndroidConfig(
                              priority: 'HIGH',
                            ),
                            apns: ApnsConfig(payload: {
                              "aps": {
                                "alert": {"title": title, "body": body},
                                "interruption-level": "time-sensitive",
                                "sound": "default",
                                "content-available": 1,
                                "category": "medication_reminder"
                              }
                            }, headers: {
                              "apns-push-type": "alert",
                              "apns-priority": "10",
                              "apns-topic": "com.novelaneuro.HomeHub"
                            }),
                            data: {
                              "eventTypeId": "2",
                              "medication_id": "${Random().nextInt(2000)}",
                              "time": DateFormat.Hm().format(DateTime.now()),
                              "title": title,
                              "message": body,
                              "reminder_id": "${Random().nextInt(2000)}"
                            },
                          ),
                        ),
                        'projects/epicarenet-5e2bb',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Done ${result}'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed Request ${e.toString()}}'),
                        ),
                      );
                    }
                  },
                  child: Text('Send'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    // final api = FirebaseCloudMessagingApi(ViewModel.singleton._authClient.value!);
                    try {
                      ViewModel.singleton.loadDevices();
                      ViewModel.singleton.loadMedicationResponses();
                      //   final apiKey = 'AIzaSyBzubvH9dWZg-LtNMvx7tq__fgPbvwe3KI';
                      //   final auth = await ViewModel.singleton._account.value?.authentication;
                      //   final result = await refreshToken(
                      //     auth!.idToken!,
                      //     'google.com',
                      //     apiKey,
                      //   );

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text('Done ${result.keys.toList()}'),
                      //   ),
                      // );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed Request ${e.toString()}}'),
                        ),
                      );
                    }
                  },
                  child: Text('Refresh'),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ListView.separated(
              itemCount: responses.length,
              shrinkWrap: true,
              separatorBuilder: (context, index) => const Divider(height: 10),
              itemBuilder: (context, index) {
                return Builder(
                  builder: (context) => MedicationResponseTile(
                    med: responses.elementAt(index).$1,
                    address: responses.elementAt(index).$2.watch(context),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

Future<Map<String, dynamic>> refreshToken(
  String token,
  String provider,
  String apiKey,
) async {
  final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey');

  final response = await http.post(url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        'postBody': 'id_token=$token&providerId=$provider',
        'requestUri': 'http://localhost',
        'returnIdpCredential': true,
        'returnSecureToken': true
      }));
  if (response.statusCode != 200) {
    throw 'Refresh token request failed: ${response.statusCode}';
  }

  final data = Map<String, dynamic>.of(jsonDecode(response.body));
  if (data.containsKey('refreshToken')) {
    return data;
  } else {
    throw 'No refresh token in response';
  }
}

// https://geocode.xyz/[request]&auth=261759532030236250355x83384
class MedicationResponseTile extends StatelessWidget {
  final MedicationResponse med;
  final AsyncState<FullAddress>? address;
  const MedicationResponseTile({
    super.key,
    required this.address,
    required this.med,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time: ' + med.timestamp.toLocal().toString()),
          Text('Name: ' + med.name.toString()),
          Text('Dose: ' + med.dose.toString()),
          Text('Action: ' + med.prettyAction),
          Builder(
            builder: (context) {
              if (address == null) return Text('No Address');
              return address!.map(
                data: (d) => Text(d.fullAddress ?? 'No Address'),
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => Text('Loading address..'),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
  static ViewModel? _singleton = ViewModel();
  static ViewModel get singleton => _singleton!;

  static late StreamSubscription sub;

  static void init() async {
    final signInResult = await _googleSignIn.signInSilently(
      suppressErrors: false,
    );

    final authentication = await signInResult?.authentication;

    await _googleSignIn.requestScopes(scopes);
    singleton._authClient.value = await _googleSignIn.authenticatedClient();

    _singleton?._account.value = signInResult;

    sub = _googleSignIn.onCurrentUserChanged.listen((event) {
      _singleton?._account.value = event;
    });
    singleton.loadMedicationResponses();
    singleton.loadDevices();
  }

  ViewModel();

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

  final _authClient = signal<auth.AuthClient?>(null);
  final _account = signal<GoogleSignInAccount?>(null);

  void loadMedicationResponses() async {
    final api = FirestoreApi(_authClient.value!);

    final result = await api.projects.databases.documents.listDocuments(
      'projects/epicarenet-5e2bb/databases/(default)/documents',
      'tmp_medication_notification_response',
      orderBy: 'timestamp desc',
    );
    final map = result.documents?.map((e) {
      if (e.fields == null) return null;

      final med = MedicationResponse.fromValueMap(e.fields!);
      if (med.long == null || med.lat == null)
        return (
          med,
          signal<AsyncState<FullAddress>?>(null),
        );
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
    final api = FirestoreApi(_authClient.value!);

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

extension on MedicationResponse {
  String get prettyAction {
    if (action.toLowerCase() == 'taken') return 'Taken';
    if (action.toLowerCase() == 'nottaken') return 'Skip';
    return action;
  }
}
