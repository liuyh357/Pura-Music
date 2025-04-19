import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:pura_music/data_controller.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    // var dataController = Provider.of<DataController>(context, listen: true);
    // var settings = dataController.settings;
    // List<String> musicFolders = List<String>.from(
    //     settings['musicFolders'].map((e) => e.toString().split('\\').last));
    // var musicFs = dataController.musicFolders.keys.toList();
    // var allMusic = dataController.allMusic;
    // var keys = settings.keys.toList();
    // var keys1 = musicFolders.keys.toList();
    return Row(
      children: [
        // Flexible(
        //     child: ListView.builder(
        //         itemBuilder: (context, index) {
        //           return ListTile(
        //             title: Text(musicFolders[index]),
        //           );
        //         },
        //         itemCount: musicFolders.length)),
        // Flexible(
        //     child: ListView.builder(
        //         itemBuilder: (context, index) {
        //           return ListTile(
        //             title: Text(musicFs[index]),
        //           );
        //         },
        //         itemCount: musicFs.length)),
      ],
    );
  }
}
