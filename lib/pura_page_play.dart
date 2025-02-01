import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pura_music/data_controller.dart';
// import 'package:pura_music/pura_main_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/pura_page_play_app_bar.dart';
// import 'package:pura_music/tools.dart';
import 'package:pura_music/ui/pura_hover_icon_button.dart';
import 'package:pura_music/ui/pura_progress_bar.dart';


class PuraPagePlay extends StatefulWidget {
  const PuraPagePlay({super.key});

  @override
  State<PuraPagePlay> createState() => _PuraPagePlayState();
}

class _PuraPagePlayState extends State<PuraPagePlay>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 调用 AutomaticKeepAliveClientMixin 的 build 方法
    final dataController = Provider.of<DataController>(context, listen: false);
    var size = MediaQuery.sizeOf(context);

    var duration = dataController.currentMusicInfo['duration']!;

    return Stack(
      children: [
        Selector<DataController, Map<String, String>>(
          selector: (_, data) => data.currentMusicInfo,
          builder: (context, musicInfo, child) {
            var artist = musicInfo['artist']!;
            var album = musicInfo['album']!;
            var bytes = dataController.getMusicImage(artist, album)!;
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(bytes), // 替换为你的图片路径
                  fit: BoxFit.cover, // 图片按照比例裁剪并填满屏幕
                ),
              ),
              width: size.width,
              height: size.height,
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 100),
          child: Scaffold(
            backgroundColor: Colors.black26,
            appBar: const PuraPagePlayAppBar(),
            body: Selector<DataController, (int, Widget)>(
              selector: (_, data) =>
                  (data.currentMusicIndex, data.currentMusicPicture),
              builder: (context, data, child) {
                var info = dataController.currentMusicInfo;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Material(
                        color: Colors.transparent,
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: 400,
                          child: Hero(
                            tag: 'play',
                            child: data.$2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${info['title']!} - ${info['artist']!}',
                        style: const TextStyle(shadows: [
                          Shadow(
                              color: Color.fromARGB(255, 108, 108, 108),
                              offset: Offset(0, 0),
                              blurRadius: 20)
                        ], color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Selector<DataController, double>(
                        selector: (_, data) => data.currentPosition,
                        builder: (context, position, child) {
                          return Hero(
                            tag: 'progress',
                            child: PuraProgressBar(
                              width: size.width / 2,
                              height: 20,
                              onDragEnd: (p0) {
                                // print('drag end: $p0');
                                dataController.setPosition(p0);
                              },
                              maxProgress: double.parse(duration),
                              showPercentage: false,
                              progressFormat: PuraProgressFormat.decimal,
                              progress: position,
                            ),
                          );
                        },
                      ),
                      Hero(
                        tag: 'controlButtons',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PuraHoverIconButton(
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white),
                              onPressed: () {
                                dataController.previousMusic();
                                setState(() {});
                              },
                            ),
                            PuraHoverIconButton(
                              icon: dataController.isPlaying
                                  ? const Icon(Icons.pause, color: Colors.white)
                                  : const Icon(Icons.play_arrow,
                                      color: Colors.white),
                              onPressed: () {
                                if (dataController.isPlaying) {
                                  dataController.pauseMusic();
                                } else {
                                  dataController.startMusic();
                                }
                                setState(() {});
                              },
                            ),
                            PuraHoverIconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white),
                              onPressed: () {
                                dataController.nextMusic();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => false; // 保活设置为 true
}
