import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'dart:io';
import 'package:watcher/watcher.dart';
// import 'bass_api/bass_api.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
// import 'Taglib_api/taglib.dart';
class DataController with ChangeNotifier {
  int indexOfPuraNavigationRail = 0;
  var mainPageController = PageController();
  Map<String, dynamic> settings = {};
  List<Watcher> musicFolderWatchers = [];
  Map<String, List<String>> musicFolders = {};
  var currentDir = Directory.current.path;
  List<String> allMusic = [];
  late AudioPlayer player1;

 Map<String,File> musicImages = {};  //用来加载专辑封面，减少读取磁盘次数

  DataController() {
    var settingsPath = '$currentDir\\settings.json';
    File settingsFile = File(settingsPath);
    if (settingsFile.existsSync()) {
      // 加载设置项
      settings = decodeJson(settingsFile.readAsStringSync());
    } else {
      resetSettings(settingsPath);
    }
    var musicFoldersPath = '$currentDir\\puraMusicFolders.json';
    var musicFoldersFile = File(musicFoldersPath);
    if (musicFoldersFile.existsSync()) {
      // 加载音乐文件夹信息
      musicFolders = decodeJson(musicFoldersFile.readAsStringSync())
          .map((k, v) => MapEntry(k, List<String>.from(v)));
    } else {
      //
    }
    player1 = AudioPlayer();
    var imagesPath = '$currentDir/images';
    if (Directory(imagesPath).existsSync()) {
      for(var file in Directory(imagesPath).listSync()){
        if(file.path.endsWith('.jpg')||file.path.endsWith('.png')||file.path.endsWith('.jpeg')){
          // print(file.path.split('\\').last.split('.').first);
          var temp = sanitizeFileName(file.path.split('\\').last.split('.').first);
          musicImages[temp] = File(file.path);
        }
      }
    }
    //更新所有的音乐文件列表
    updateAllMusic();
  }

  void changeIndexOfPuraNavigationRail(int index) {
    indexOfPuraNavigationRail = index;
    mainPageController.jumpToPage(index);
    notifyListeners();
  }

  void resetSettings(String filePath) {
    settings = {
      "settingsPath": filePath,
      "isCustomTheme": false,
      "themeColor": "blue",
      "language": "zh",
      "darkMode": false,
      "musicFolders": [],
    };
    saveJson(settings, filePath);
  }

  void addMusicFolder(String folderPath) {
    // 用户执行添加文件夹操作时调用的函数，更新设置和musicFolders
    List<String> removedFolders = [];
    // 判断是否已经添加过该文件夹
    for (String folder in settings["musicFolders"]) {
      // if (folderPath.startsWith(folder)) {
      //   return;
      // }
      if(folder.startsWith(folderPath)){
        removedFolders.add(folder);
      }
    }
    for(String folder in removedFolders){
      removeMusicFolder(folder);
    }

    settings["musicFolders"].add(folderPath);
    saveJson(settings, settings["settingsPath"]);
    //   更新musicFolders
    _updateMusicFolders(folderPath);
    saveJson(musicFolders, '$currentDir\\puraMusicFolders.json');
    updateAllMusic();
  }

  void _updateMusicFolders(String mainFolderPath) {
    List<String> subFolders = [];
    musicFolders[mainFolderPath] = [];
    for (String folder
    in Directory(mainFolderPath).listSync().map((e) => e.path).toList()) {
      if (Directory(folder).existsSync()) {
        subFolders.add(folder);
        musicFolders[mainFolderPath]?.add(folder);
        _updateMusicFolders(folder);
        notifyListeners();
      }
    }
  }

  void removeMusicFolder(String folderPath) {
    // 用户执行删除文件夹操作时调用的函数，更新设置和musicFolders
    settings["musicFolders"].remove(folderPath);
    saveJson(settings, settings["settingsPath"]);
    //   更新musicFolders
    _deleteMusicFolders(folderPath);
    saveJson(musicFolders, '$currentDir\\puraMusicFolders.json');
    updateAllMusic();
    notifyListeners();
  }

  void _deleteMusicFolders(String folderPath) {
    //   删除文件夹及其子文件夹
    for (String folder in musicFolders[folderPath]!) {
      _deleteMusicFolders(folder);
    }
    musicFolders.remove(folderPath);
  }

  void updateAllMusic() {
    // 更新所有音乐文件列表
    allMusic = [];
    for (String folder in musicFolders.keys.toList()) {
      allMusic.addAll(getMusic(folder));
    }
  }

  List<String> getMusic(String folderPath) {
    // 获取文件夹下所有音乐文件路径
    // var path = '$currentDir\\avcodec-61.dll';
    // if (File(path).existsSync()) {
    //   final DynamicLibrary dynamicLibrary = DynamicLibrary.open(
    //       'D:\\FlutterProjects\\AS\\pura_music\\avformat-61.dll');
    //   var version = ffmpeg_format(dynamicLibrary).avformat_version();
    //   print(version);
    //   dynamicLibrary.close();
    // }
    var files = Directory(folderPath)
        .listSync()
        .where((e) => isMusicFile(e.path))
        .map((e) => e.path)
        .toList();
    for (var file in files) {
      // getMusicInfo(file);
    }
    return files;
  }

  bool isMusicFile(String fileName) {
    fileName = fileName.toLowerCase();
    bool isMusic = fileName.endsWith('.mp3') ||
        fileName.endsWith('.flac') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.aac') ||
        fileName.endsWith('.m4a') ||
        fileName.endsWith('.ogg') ||
        fileName.endsWith('.wma') ||
        fileName.endsWith('.aiff') ||
        fileName.endsWith('.dsd');
    return isMusic;
  }
  String sanitizeFileName(String fileName) {
    // 去除文件名中的不合法字符
    // 定义不合法的字符
    const invalidChars = r'\/:*?"<>|.';

    // 替换不合法字符为空字符
    String sanitizedName = fileName.replaceAll(RegExp('[$invalidChars]'), '_');

    // 可以选择限制字符长度，最大限制为255（Windows文件名最大字符数）
    if (sanitizedName.length > 255) {
      sanitizedName = sanitizedName.substring(0, 255);
    }

    return sanitizedName;
  }
  Map<String, String> getMusicInfo(String filePath) {
    // 获取音乐文件的信息
    // filePath = "D:\\FlutterProjects\\AGA-孤雏.mp3";
    final track = File(filePath);
    final metaData = readMetadata(track,getImage: true);
    Map<String, String> info = {};
    info['title'] = metaData.title ?? 'unknown';
    info['artist'] = metaData.artist ?? 'unknown';
    info['album'] = metaData.album ?? 'unknown';

    String folderPath = '$currentDir\\images';
    if (!Directory(folderPath).existsSync()) {
      Directory(folderPath).createSync();
    }
    String imagePath = '$folderPath\\${sanitizeFileName(info['artist']!)}-${sanitizeFileName(info['album']!)}.jpg';
    if (!File(imagePath).existsSync()) {
      if(metaData.pictures.isNotEmpty) {
        File(imagePath).writeAsBytesSync(metaData.pictures.first.bytes);
        musicImages[info['album']!] = File(imagePath);
      }
      else{
        musicImages[info['album']!] = File('assets\\images\\PuraMusicIcon1.jpg');
      }
    }
      // print(info);
    return info;
  }
  File? getMusicImage(String artist,String album) {
    var key = "${sanitizeFileName(artist)}-${sanitizeFileName(album)}";
    if(musicImages.containsKey(key)){
      return musicImages[key];
    }
    return null;
  }
}
