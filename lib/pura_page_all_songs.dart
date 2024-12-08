import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';
import 'package:pura_music/pura_page_all_songs_card.dart';
import 'package:file_picker/file_picker.dart';

class PuraPageAllSongs extends StatefulWidget {
  const PuraPageAllSongs({Key? key}) : super(key: key);

  @override
  _PuraPageAllSongsState createState() => _PuraPageAllSongsState();
}

class _PuraPageAllSongsState extends State<PuraPageAllSongs> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var dataController = Provider.of<DataController>(context, listen: false);
    return Column(
        // padding: const EdgeInsets.only(left: 10, right: 10),
        children: [
          IconButton(
            onPressed: () async {
              String? path = await FilePicker.platform.getDirectoryPath();
              if (context.mounted) {
                dataController.addMusicFolder(path!);
              }
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () async {
              String? path = await FilePicker.platform.getDirectoryPath();
              if (context.mounted) {
                dataController.removeMusicFolder(path!);
              }
            },
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () {
              dataController.getMusicInfo(' ');
            },
            icon: const Icon(Icons.telegram_sharp),
          ),
          Expanded(
            child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        screenWidth ~/ 200 > 6 ? 6 : screenWidth ~/ 200,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: dataController.allMusic.length,
                itemBuilder: (context, index) {
                  var info = dataController
                      .getMusicInfo(dataController.allMusic[index]);
                  String songName = info['title'].toString();
                  String artistName = info['artist'].toString();
                  String albumName = info['album'].toString();

                  return PuraPageAllSongsCard(
                    songName: songName,
                    artistName: artistName,
                    albumName: albumName,
                  );
                }),
          ),
        ]);
  }
}
