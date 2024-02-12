import 'dart:math';

import 'package:fcm_admin_portal/models.dart';
import 'package:fcm_admin_portal/sign_in_button.dart';
import 'package:fcm_admin_portal/view_model.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/fcm/v1.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SendReminderPage extends StatefulWidget {
  const SendReminderPage({super.key});

  @override
  State<SendReminderPage> createState() => _SendReminderPageState();
}

class _SendReminderPageState extends State<SendReminderPage> {
  List<Device> devices = [];
  Device? selectedDevice;
  String token = '';
  String title = '';
  String body = '';

  @override
  void initState() {
    super.initState();
    ViewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: getBody(),
    );
  }

  Widget getBody() {
    final account = ViewModel.singleton.account.watch(context);
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
                    final api = FirebaseCloudMessagingApi(ViewModel.singleton.authClient.value!);
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

extension on MedicationResponse {
  String get prettyAction {
    if (action.toLowerCase() == 'taken') return 'Taken';
    if (action.toLowerCase() == 'nottaken') return 'Skip';
    return action;
  }
}
