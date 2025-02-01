import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';
import 'package:pura_music/pura_page_all_songs_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pura_music/util/file_utils.dart';

class PuraPageAllSongs extends StatefulWidget {
  const PuraPageAllSongs({super.key});

  @override
  _PuraPageAllSongsState createState() => _PuraPageAllSongsState();
}

class _PuraPageAllSongsState extends State<PuraPageAllSongs>
    with AutomaticKeepAliveClientMixin {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用 super.build 以保持状态
    count++;
    var screenWidth = MediaQuery.sizeOf(context).width;
    var dataController = Provider.of<DataController>(context, listen: false);
    return ColoredBox(
      color: const Color.fromARGB(0, 232, 239, 243),
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(children: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  var result = await FileUtils.pickFolder(context);
                  var path = result?.$1;
                  if (context.mounted && path != null) {
                    setState(() {
                      dataController.addMusicFolder(folderPath: path);
                      print("add music folder: $path");
                    });
                  }
                },
                icon: const Icon(Icons.add),
              ),
              IconButton(
                onPressed: () async {
                  var result = await FileUtils.pickFolder(context);
                  var path = result?.$1;
                  if (context.mounted && path != null) {
                    setState(() {
                      dataController.removeMusicFolder(folderPath: path);
                      print("remove music folder: $path");
                    });
                  }
                },
                icon: const Icon(Icons.delete),
              ),
              Text("重新渲染次数：$count"),
            ],
          ),
          Expanded(
            child: Selector<DataController,
                (Map<String, Uint8List>, List<String>)>(
              selector: (context, dataController) =>
                  (dataController.musicImages, dataController.allMusic),
              shouldRebuild: (prev, next) => prev.$2.length != next.$2.length,
              builder: (context, data, child) {
                return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            screenWidth ~/ 200 > 7 ? 7 : screenWidth ~/ 200,
                        childAspectRatio: 0.80,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10),
                    itemCount: dataController.allMusic.length +
                        (screenWidth ~/ 200 > 7 ? 7 : screenWidth ~/ 200),
                    itemBuilder: (context, index) {
                      if (index < dataController.allMusic.length) {
                        // print("allmusic length: ${dataController.allMusic.length}");
                        // print("allmusic: ${dataController.allMusic}");
                        // 记录图片加载开始时间
                        // DateTime startTime = DateTime.now();
                        var filePath = dataController.allMusic[index];
                        var info = dataController.getMusicInfoByPath(filePath);
                        String songName = info['title']!;
                        String artistName = info['artist']!;
                        String albumName = info['album']!;

                        var imgBytes =
                            dataController.getMusicImage(artistName, albumName);
                        Image img;
                        if (imgBytes != null) {
                          img = Image.memory(imgBytes);
                        } else {
                          img = Image.asset(
                              'assets/images/PuraMusicIcon1_square.png');
                        }
                        // 记录图片加载结束时间
                        // DateTime endTime = DateTime.now();

                        return Column(
                          children: [
                            PuraPageAllSongsCard(
                              songName: songName,
                              artistName: artistName,
                              albumName: albumName,
                              index: index,
                              child: img,
                            ),
                            // Text(
                            //     "加载耗时：${endTime.difference(startTime).inMilliseconds}ms"),
                          ],
                        );
                      }
                      return Container();
                    });
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
