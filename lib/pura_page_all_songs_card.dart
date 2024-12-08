import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_controller.dart';

class PuraPageAllSongsCard extends StatefulWidget {
  const PuraPageAllSongsCard(
      {super.key,
      required this.songName,
      required this.artistName,
      required this.albumName});

  final String songName;
  final String artistName;
  final String albumName;

  @override
  _PuraPageAllSongsCardState createState() => _PuraPageAllSongsCardState();
}

class _PuraPageAllSongsCardState extends State<PuraPageAllSongsCard> {
  @override
  Widget build(BuildContext context) {
    // var currentDirectory = Directory.current.path;
    // var imagePath = '$currentDirectory\\images\\${widget.albumName}.jpg';
    var dataController = Provider.of<DataController>(context, listen: false);
    var album = widget.albumName;
    var artist = widget.artistName;
    var image = dataController.getMusicImage(artist, album);
    // print(widget.image.toString());
    return Column(
      children: [
        Card(
          elevation: 5,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: image == null
             ? Image.asset('assets/images/PuraMusicIcon1.png')
              : Image.file(image),
        )
      ],
    );
  }
}
