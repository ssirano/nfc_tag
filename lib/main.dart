import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:logger/logger.dart';
import 'package:android_intent/android_intent.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String tagInfo = "No NFC tag read yet";
  bool tagAvailable = false;
  Ndef? ndefInstance;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  _checkNfcAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.NFC_SETTINGS',
      );
      await intent.launch();
      logger.e("NFC Unavailable, opening settings");
    } else {
      logger.d("NFC is available");
    }
  }

  void _startNfcSession() {
    logger.d("NFC session started");
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      Ndef? ndef = Ndef.from(tag);
      final id = tag.data['id'];
      final type = tag.data['type'];
      logger.d('Tag ID: $id');
      logger.d('Tag Type: $type');
      logger.d("Full tag info: ${tag.data}");

      if (ndef == null) {
        logger.w("This tag does not support NDEF.");
        return;
      }

      final ndefMessage = ndef.cachedMessage?.records.map((record) {
        return String.fromCharCodes(record.payload);
      }).join(', ');

      setState(() {
        tagAvailable = true;
        ndefInstance = ndef;
        tagInfo = "Tag ID: $id\nTag Type: $type\nTag Content: $ndefMessage";
      });

      if (ndef.isWritable) {
        logger.i("This tag is writable.");
      } else {
        logger.i("This tag is not writable.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFC Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tagInfo),
            ElevatedButton(
              onPressed: () {
                _startNfcSession();
              },
              child: Text('Start NFC Session'),
            ),
          ],
        ),
      ),
    );
  }
}
