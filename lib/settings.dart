import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    var dataController = Provider.of<DataController>(context, listen: true);
    var settings = dataController.settings;
    var musicFolders = dataController.musicFolders;
    var allMusic = dataController.allMusic;
    var keys = settings.keys.toList();
    var keys1 = musicFolders.keys.toList();
    return Container(
      child: ListView.builder(itemCount: allMusic.length,itemBuilder: (context, index) {
        return Row(
          children: [
            // Text("${keys1[index]} : ${musicFolders[keys1[index]].toString()}"),
            Text(allMusic[index]),
          ],
        );
      }),
    );
  }
}
