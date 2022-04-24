import 'package:flutter/material.dart';
import 'package:super_logger/utils/extensions.dart';

class RecordAudioScreen extends StatefulWidget {
  const RecordAudioScreen({Key? key}) : super(key: key);

  @override
  _RecordAudioScreenState createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  String _name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newRecording),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                label: Text("Label"),
              ),
              onChanged: (s) => setState(() {
                _name = s;
              }),
            ),
            const SizedBox(
              height: 24,
            ),
            const Text("04:00"),
            const SizedBox(
              height: 16,
            ),
            TextButton(
              onPressed: () {},
              child: const Text("Stop"),
            ),
          ],
        ),
      ),
    );
  }
}
