import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';
import 'package:pura_music/pura_page_play.dart';
import 'package:pura_music/ui/pura_hover_icon_button.dart';
import 'package:pura_music/ui/pura_progress_bar.dart';
// import 'tools.dart';

class PuraMainBottomBar extends StatefulWidget {
  const PuraMainBottomBar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PuraMainBottomBarState createState() => _PuraMainBottomBarState();
}

class _PuraMainBottomBarState extends State<PuraMainBottomBar> {
  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    var size = MediaQuery.sizeOf(context);
    var duration = dataController.currentMusicInfo['duration']!;
    return Selector<DataController, (int, String, bool)>(
      selector: (_, dataController) => (
        dataController.currentMusicIndex,
        dataController.currentMusicList,
        dataController.isPlaying
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, data, child) {
        var dataController =
            Provider.of<DataController>(context, listen: false);
        var info = dataController.currentMusicInfo;
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: Material(
            color: Colors.transparent,
            shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0))),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(137, 137, 137, 0.494),
                // borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                            onTap: () {
                              // Navigator.pushNamed(context, '/play');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PuraPagePlay(),
                                  maintainState: true, // 确保源页面未被销毁
                                ),
                              );
                            },
                            child: SizedBox(
                              height: 50,
                              child: Hero(
                                  tag: 'play',
                                  child: dataController.currentMusicPicture),
                            )),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${info['title']!} - ${info['artist']!}',
                            style: const TextStyle(shadows: [
                              Shadow(
                                  color: Color.fromARGB(255, 108, 108, 108),
                                  offset: Offset(0, 0),
                                  blurRadius: 20)
                            ], color: Colors.white),
                          ),
                          Hero(
                            tag: 'controlButtons',
                            child: Row(
                              children: [
                                PuraHoverIconButton(
                                  icon: const Icon(Icons.skip_previous,
                                      color: Colors.white),
                                  onPressed: () {
                                    dataController.previousMusic();
                                  },
                                ),
                                PuraHoverIconButton(
                                  icon: dataController.isPlaying
                                      ? const Icon(Icons.pause,
                                          color: Colors.white)
                                      : const Icon(Icons.play_arrow,
                                          color: Colors.white),
                                  onPressed: () {
                                    if (dataController.isPlaying) {
                                      dataController.pauseMusic();
                                    } else {
                                      // dataController.startMusic();
                                      dataController.playMusic(dataController.currentMusicIndex, dataController.currentMusicList);
                                    }
                                  },
                                ),
                                PuraHoverIconButton(
                                  icon: const Icon(Icons.skip_next,
                                      color: Colors.white),
                                  onPressed: () {
                                    dataController.nextMusic();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Selector<DataController, double>(
                              selector: (_, data) => data.currentPosition,
                              builder: (context, position, child) {
                                return Column(
                                  children: [
                                    // Text('position: $position'),
                                    Hero(
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
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
