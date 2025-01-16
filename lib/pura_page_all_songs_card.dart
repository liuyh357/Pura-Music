import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_controller.dart';

class PuraPageAllSongsCard extends StatelessWidget {
  const PuraPageAllSongsCard({
    super.key,
    required this.songName,
    required this.artistName,
    required this.albumName,
    required this.child,
    required this.index,
  });

  final String songName;
  final String artistName;
  final String albumName;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    var dataController = Provider.of<DataController>(context, listen: false);
    // var album = albumName;
    // var artist = artistName;
    // var imageBytes = dataController.getMusicImage(artist, album);

    return Column(
      children: [
        Card(
          elevation: 5,
          clipBehavior: Clip.antiAlias,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
          child: _MusicPicture(
              dataController: dataController, index: index, child: child),
        ),
        Text(songName,
            style: const TextStyle(overflow: TextOverflow.ellipsis)
                .useSystemChineseFont()),
        Text("$artistName-$albumName",
            style: const TextStyle(overflow: TextOverflow.ellipsis)
                .useSystemChineseFont()),
      ],
    );
  }
}

class _MusicPicture extends StatefulWidget {
  final Widget child;
  final DataController dataController;
  final int index;
  const _MusicPicture(
      {required this.child, required this.dataController, required this.index});
  @override
  State<StatefulWidget> createState() {
    return _MusicPictureState();
  }
}

class _MusicPictureState extends State<_MusicPicture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      animationBehavior: AnimationBehavior.preserve,
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 15.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isHover = false;
  bool isCurrent = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          bool isPlaying = widget.dataController.isPlaying;
          int index = widget.dataController.currentMusicIndex;
          isCurrent = (index == widget.index) && isPlaying;
          isHover = true;
          _controller.forward();
        });
      },
      onExit: (event) {
        setState(() {
          isHover = false;
          _controller.reverse();
        });
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: _animation.value, sigmaY: _animation.value),
                      child: InkWell(
                        onTap: () {
                          bool isPlaying = widget.dataController.isPlaying;
                          int index = widget.dataController.currentMusicIndex;
                          if (!isPlaying || index != widget.index) {
                            // print("play");
                            widget.dataController
                                .playMusic(widget.index, "allMusic");
                          } else {
                            // print("pause");
                            widget.dataController.pauseMusic();
                          }
                          isPlaying = widget.dataController.isPlaying;
                          index = widget.dataController.currentMusicIndex;
                          setState(() {
                            isCurrent = (index == widget.index) && isPlaying;
                            // print(
                            //     "isPlaying: $isPlaying  index: $index  widget.index: ${widget.index}");
                            // print("isCurrent: $isCurrent");
                          });
                        },
                        child: Icon(
                          isCurrent ? Icons.pause : Icons.play_arrow,
                          size: 50,
                          color: isHover ? Colors.white : Colors.transparent,
                          shadows: [
                            Shadow(
                                color: isHover
                                    ? const Color.fromARGB(255, 151, 151, 151)
                                    : Colors.transparent,
                                blurRadius: 40,
                                offset: const Offset(0, 0))
                          ],
                        ),
                      ));
                },
              ))
        ],
      ),
    );
  }
}
