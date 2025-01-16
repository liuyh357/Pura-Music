import 'dart:async';
// import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'dart:io';
import 'package:watcher/watcher.dart';
// import 'bass_api/bass_api.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:image/image.dart' as img;
import 'bass_api/bass.dart';
import 'bass_api/bass_fx.dart' as bassfx;
import 'bass_api/bass_mix.dart' as bassmix;
import 'bass_api/bass_wasapi.dart' as basswasapi;

/// 定义 Native 函数类型
typedef NativeCallback = Void Function(UnsignedLong param1, UnsignedLong param2,
    UnsignedLong param3, Pointer<Void> param4);
typedef WASAPICallback = UnsignedLong Function(Pointer<Void>, UnsignedLong, Pointer<Void>);

/// 定义对应的 Dart 函数类型
typedef DartCallback = void Function(
    int param1, int param2, int param3, Pointer<Void> param4);

class DataController with ChangeNotifier {
  int indexOfPuraNavigationRail = 0;
  var mainPageController = PageController();
  Map<String, dynamic> settings = {};

  ///监听文件更改情况
  List<Watcher> musicFolderWatchers = [];

  ///musicFolders：保存key下包含音乐文件的一级目录，并且key一定包含音乐文件
  ///
  ///主要用于：删除文件夹时，可利用musicFolders删除已经记录的其下所有子文件夹（含自身），减少磁盘读取次数
  Map<String, List<String>> musicFolders = {};
  var currentDir = Directory.current.path;
  List<String> allMusic = [];

  ///用来加载专辑封面，减少读取磁盘次数
  Map<String, Uint8List> musicImages = {};

  ///用来存储音乐文件信息
  Map<String, Map<String, String>> musicInfos = {};

  ///当前播放的音乐列表名
  String currentMusicList = "allMusic";

  ///当前播放的音乐文件索引
  int currentMusicIndex = 0;

  ///当前播放的音乐文件信息
  Map<String, String> currentMusicInfo = {
    "title": "unknown",
    "artist": "unknown",
    "album": "unknown",
    "duration": "0",
  };
  Widget currentMusicPicture = Image.asset(
    'assets/images/PuraMusicIcon1_square.png',
    fit: BoxFit.fill,
  ); //当前播放的音乐文件专辑封面
  // Duration currentPosition = Duration.zero; //当前播放的位置
  ///当前是否正在播放
  bool isPlaying = false;

  ///播放模式 0：顺序播放  1：单曲循环  2：随机播放
  int playMode = 0;

  ///当前播放位置 [double] in seconds
  double currentPosition = 0;

  ///更新currentPosition的定时器
  Timer? _timer; // 定时器
  late bass_api bass;
  late bassfx.bass_fx_api bassFx;
  late bassmix.bass_mix_api bassMix;
  late basswasapi.bass_wasapi_api bassWasapi;
  int currentStream = 0;
  int nextStream = 0;
  int silenceStream = 0;
  int mainMixer = 0;

  late DateTime start = DateTime.now();
  late DateTime end = DateTime.now();

  //todo: musicList：存储所有额外添加的音乐列表信息, 应该是一个map，key为list的名称，value为list 或者：改为存储对象的实例，将音乐列表封装成一个类
  //todo: 如果改成用类来封装，那么可以保存该列表包含的文件夹路径（和对应音乐的索引？），以便后续删除时减少查询的次数

  static final DataController _instance = DataController._internal();
  static DataController getInstance() => _instance;
  DataController._internal() {
    start = DateTime.now();
    var settingsPath = '$currentDir\\settings.json';
    File settingsFile = File(settingsPath);
    if (settingsFile.existsSync()) {
      // 加载设置项
      settings = decodeJson(settingsFile.readAsStringSync());
    } else {
      _resetSettings(settingsPath);
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
    var imagesPath = '$currentDir\\images';
    if (Directory(imagesPath).existsSync()) {
      for (var file in Directory(imagesPath).listSync()) {
        if (file.path.endsWith('.jpg') ||
            file.path.endsWith('.png') ||
            file.path.endsWith('.jpeg')) {
          // print(file.path.split('\\').last.split('.').first);
          var temp =
              _sanitizeFileName(file.path.split('\\').last.split('.').first);
          musicImages[temp] = File(file.path).readAsBytesSync();
        }
      }
    }
    //更新所有的音乐文件列表
    // updateAllMusic();
    initBASS();
    loadMusicFolders();
    initLastPlayMusicInfo();
    end = DateTime.now();
    print(
        'DataController init time: ${end.difference(start).inMilliseconds}ms');
  }

  ///初始化上次播放音乐的信息
  Future<void> initLastPlayMusicInfo() async {
    if (settings.containsKey("currentMusicList") &&
        settings.containsKey("currentMusicIndex") &&
        settings.containsKey("currentMusicInfo")) {
      currentMusicList = settings["currentMusicList"];
      currentMusicIndex = settings["currentMusicIndex"];
      currentMusicInfo =
          settings["currentMusicInfo"].map<String, String>((key, value) {
        return MapEntry(key.toString(), value.toString());
      });
      // print(temp);
      if (currentMusicInfo.containsKey("artist") &&
          currentMusicInfo.containsKey("album")) {
        var key =
            _getKey(currentMusicInfo["artist"]!, currentMusicInfo["album"]!);
        if (musicImages.containsKey(key)) {
          currentMusicPicture = Image.memory(
            musicImages[key]!,
            fit: BoxFit.fill,
          );
        }
      }
    }
  }

  /// 从之前保存的settings.json文件中读取音乐文件夹
  Future<void> loadMusicFolders() async {
    // print(settings["musicFolders"]);
    for (String folder in settings["musicFolders"]) {
      // var ml = getMusic(folder);
      // print(folder);
      // await Isolate.spawn(getMusic,folder);
      await _getMusic(folder);
    }
    // print("allMusic: $allMusic");
    notifyListeners();
  }

  void initBASS() {
    var bassDy = DynamicLibrary.open('$currentDir\\bass.dll');
    var bassfxDy = DynamicLibrary.open('$currentDir\\bass_fx.dll');
    var bassmixDy = DynamicLibrary.open('$currentDir\\bassmix.dll');
    var basswasapiDy = DynamicLibrary.open('$currentDir\\basswasapi.dll');
    bass = bass_api(bassDy);
    bassFx = bassfx.bass_fx_api(bassfxDy);
    bassMix = bassmix.bass_mix_api(bassmixDy);
    bassWasapi = basswasapi.bass_wasapi_api(basswasapiDy);

    var version = bassFx.BASS_FX_GetVersion();
    print('BASS_FX version: $version');

    version = bassMix.BASS_Mixer_GetVersion();
    print('BASS_Mixer version: $version');

    // 设置设备流的缓冲区大小
    // bass.BASS_SetConfig(BASS_CONFIG_DEV_BUFFER, 30); // 毫秒

    if (bass.BASS_Init(-1, 44100, 0, nullptr, nullptr) == 0) {
      print('BASS_Init failed with error: ${bass.BASS_ErrorGetCode()}');
      return;
    }
    mainMixer = bassMix.BASS_Mixer_StreamCreate(
        44100, 2, BASS_STREAM_DECODE | bassmix.BASS_MIXER_QUEUE);
    if (mainMixer == 0) {
      print(
          'BASS_Mixer_StreamCreate failed with error: ${bass.BASS_ErrorGetCode()}');
      return;
    }
    if(bassWasapi.BASS_WASAPI_Init(-1, 44100, 0, 0, 0.03, 0, nullptr, nullptr) == 0){
      print('BASS_WASAPI_Init failed with error: ${bass.BASS_ErrorGetCode()}');
    }
    // var path = '$currentDir\\silence.mp3';
    // var pathPtr = path.replaceAll('\\', '/').toNativeUtf16();
    // silenceStream = bass.BASS_StreamCreateFile(
    //     0, pathPtr.cast<Char>().cast<Void>(), 0, 0, BASS_UNICODE);
    // bass.BASS_ChannelPlay(silenceStream, 1);
    loadPlugin('bassflac');
    loadPlugin('bassopus');
    // loadPlugin('bass_fx');
    loadPlugin('bassdsd');
    // loadPlugin('bassmix');
    loadPlugin('basswv');
    loadPlugin('basscd');
  }

  void loadPlugin(String pluginName) {
    var pluginPath = '$currentDir\\$pluginName.dll';
    var pluginHandle = bass.BASS_PluginLoad(
        pluginPath.toNativeUtf16().cast<Char>(), BASS_UNICODE);
    if (pluginHandle == 0) {
      print(
          'Failed to load $pluginName plugin with error: ${bass.BASS_ErrorGetCode()}');
    } else {
      print('$pluginName plugin loaded successfully!');
    }
  }

  void changeIndexOfPuraNavigationRail(int index) {
    indexOfPuraNavigationRail = index;
    mainPageController.jumpToPage(index);
    notifyListeners();
  }

  void _resetSettings(String filePath) async {
    settings = {
      "settingsPath": filePath,
      "isCustomTheme": false,
      "themeColor": "blue",
      "language": "zh",
      "darkMode": false,
      "musicFolders": [],
      "volume": 1.0,
      "playMode": 0,
      "currentMusicList": "allMusic",
      "currentMusicIndex": 0,
      "currentMusicInfo": {
        "title": "unknown",
        "artist": "unknown",
        "album": "unknown",
        "duration": "0",
      },
      "currentPosition": 0,
    };
    await saveJson(settings, filePath);
  }

  String addMusicFolder(
      {required String folderPath,
      bool withSubFolders = true,
      bool save = true}) {
    bool isAdded = settings["musicFolders"].contains(folderPath);
    if (withSubFolders == false && isAdded) {
      // // todo 如果已经包含该文件夹，可以继续遍历子文件夹
      return folderPath;
    }
    List<String> subFolders = [];

    for (var fileEntity in Directory(folderPath).listSync()) {
      if (withSubFolders) {
        if (Directory(fileEntity.path).existsSync()) {
          var subDir = addMusicFolder(
              folderPath: fileEntity.path, withSubFolders: true, save: false);
          // if (subDir.isNotEmpty) {
          subFolders.add(subDir);
          // }
        }
      }
      if (isAdded == false &&
          File(fileEntity.path).existsSync() &&
          isMusicFile(fileEntity.path)) {
        allMusic.add(fileEntity.path);

        // print("add music: $fileEntity.path");
      }
    }

    if (save) {
      // notifyListeners();
    }
    bool containMusic = containMusicFile(folderPath);
    if (containMusic) {
      settings["musicFolders"].add(folderPath);
    }
    // if(containMusic || withSubFolders) {
    musicFolders[folderPath] = subFolders;
    // }
    if (save) {
      saveJson(settings, settings["settingsPath"]);
      saveJson(musicFolders, '$currentDir\\puraMusicFolders.json');
    }
    //   更新musicFolders
    // _updateMusicFolders(folderPath);

    // updateAllMusic(); //!del: 不应该每添加一个文件夹就重新扫描一次全部的音乐文件，应该只扫描新增文件夹下的文件
    return folderPath;
    // if (containMusic) {
    //   return folderPath;
    // }
    // return "";
  }

  bool containMusicFile(String filePath) {
    var dir = Directory(filePath);
    if (dir.existsSync()) {
      for (String file in dir.listSync().map((e) => e.path).toList()) {
        if (File(file).existsSync() && isMusicFile(file)) {
          return true;
        }
      }
    }
    return false;
  }

  void removeMusicFolder(
      {required String folderPath,
      bool withSubFolders = true,
      bool save = true}) {
    // 用户执行删除文件夹操作时调用的函数，更新设置和musicFolders
    bool isAdded = settings["musicFolders"].contains(folderPath);
    if (isAdded == false && withSubFolders == false) {
      return;
    }
    if (isAdded == true) {
      // return;
      settings["musicFolders"].remove(folderPath);
    }

    print("remove music folder: $folderPath");
    if (withSubFolders &&
        musicFolders.containsKey(folderPath) &&
        musicFolders[folderPath] != []) {
      for (String folder in musicFolders[folderPath]!) {
        removeMusicFolder(
            folderPath: folder, withSubFolders: true, save: false);
      }
    }
    if (save) {
      saveJson(settings, settings["settingsPath"]);
      saveJson(musicFolders, '$currentDir\\puraMusicFolders.json');
    }
    List<String> delMusic = [];
    for (String music in allMusic) {
      if (music.startsWith(folderPath)) {
        delMusic.add(music);
      }
    }
    allMusic.removeWhere((element) => delMusic.contains(element));
    //   更新musicFolders
    // _deleteMusicFolders(folderPath);
    // // todo: 需要更新所有音乐列表中的音乐，不只是allMusic

    // updateAllMusic();
    if (save) {
      // notifyListeners();
    }
  }

  ///后续可能用来刷新音乐列表
  void _updateAllMusic() {
    // 更新所有音乐文件列表
    allMusic = [];
    for (String folder in musicFolders.keys.toList()) {
      _getMusic(folder);
    }
  }

  /// 获取key
  String _getKey(String artist, String album) {
    return "${_sanitizeFileName(artist)}-${_sanitizeFileName(album)}";
  }

  /// 获取文件夹下所有音乐文件，包括路径和音频元数据
  Future<void> _getMusic(String folderPath) async {
    // print("get music from $folderPath");
    var files = Directory(folderPath)
        .listSync()
        .where((e) => isMusicFile(e.path))
        .map((e) => e.path)
        .toList();
    // print("files: $files");
    //将所有扫描到的音乐的元数据信息保存到musicInfos中，同时保存专辑封面到images文件夹和musicImages中
    for (var file in files) {
      var info = getMusicInfo(filePath: file, getAlbumArt: true);
      // todo: 后面根据图片的加载情况来开启异步加载图片（遍历musicImages）
      var key = file;
      musicInfos[key] = info;
    }
    allMusic.addAll(files);
    // return files;
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

  String _sanitizeFileName(String fileName) {
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

  Map<String, String> getMusicInfo(
      {required String filePath, bool getAlbumArt = false}) {
    // 获取音乐文件的信息
    // filePath = "D:\\FlutterProjects\\AGA-孤雏.mp3";
    final track = File(filePath);
    final metaData = readMetadata(track, getImage: getAlbumArt);
    Map<String, String> info = {};
    info['title'] = metaData.title ?? 'unknown';
    info['artist'] = metaData.artist ?? 'unknown';
    info['album'] = metaData.album ?? 'unknown';

    /// in seconds
    double duration = 0;
    if (metaData.duration?.inMilliseconds == null) {
      throw Exception("duration is null");
    } else {
      duration = metaData.duration!.inMilliseconds.toDouble() / 1000;
    }

    info['duration'] = duration.toString();
    musicInfos[filePath] = info;
    if (getAlbumArt) {
      String folderPath = '$currentDir\\images';
      if (!Directory(folderPath).existsSync()) {
        Directory(folderPath).createSync();
      }

      var key =
          // "${_sanitizeFileName(info['artist']!)}-${_sanitizeFileName(info['album']!)}";
          _getKey(info['artist']!, info['album']!);
      String imagePath =
          // '$folderPath\\${_sanitizeFileName(info['artist']!)}-${_sanitizeFileName(info['album']!)}.jpg';
          '$folderPath\\$key.jpg';
      if (!File(imagePath).existsSync()) {
        if (metaData.pictures.isNotEmpty) {
          // 保存专辑封面略缩图到images文件夹
          // var file = File(imagePath);

          var image = img.decodeImage(metaData.pictures.first.bytes);
          var resizedImageBytes = img.copyResize(image!, width: 400);
          var jpegBytes = img.encodeJpg(resizedImageBytes);
          File(imagePath).writeAsBytesSync(jpegBytes);
          musicImages[key] = jpegBytes;
        } else {
          musicImages[key] = File('assets\\images\\PuraMusicIcon1_square.png')
              .readAsBytesSync();
        }
      }
    }
    // print(info);
    return info;
  }

  // todo:获取高清图片
  Uint8List? getMusicImage(String artist, String album) {
    // var key = "${_sanitizeFileName(artist)}-${_sanitizeFileName(album)}";
    var key = _getKey(artist, album);
    // var key = "$artist-$album";
    if (!musicImages.containsKey(key)) {
      musicImages[key] =
          File('assets\\images\\PuraMusicIcon1_square.png').readAsBytesSync();
    }
    return musicImages[key];
  }

  Map<String, String> getMusicInfoByPath(String path) {
    if (musicInfos.containsKey(path)) {
      return musicInfos[path]!;
    } else {
      print("musicInfos not contain $path");
      return getMusicInfo(filePath: path, getAlbumArt: true);
    }
  }

  String getPathByIndex(int index, String musicList) {
    if (musicList == "allMusic") {
      return allMusic[index];
    }
    return "";
  }

  List<String> getListByName(String musicList) {
    if (musicList == "allMusic") {
      return allMusic;
    }
    return [];
  }

  int getIndexByMode(int index, int mode, String musicList) {
    // todo:将数字改成enum
    switch (mode) {
      case 0:
        return index;
      case 1:
        return (index + 1) % getListByName(musicList).length;
      default:
        return 0;
    }
  }

  /// 播放音乐
  /// index: 音乐文件在当前音乐列表的索引
  /// musicList: 音乐列表名
  /// 
  void _playMusic({required int index, required String musicList}) {
    int nextIndex = getIndexByMode(index, playMode, musicList);
    String filePath = getPathByIndex(index, musicList);
    String nextFilePath =
        getPathByIndex(nextIndex, musicList);
    bass.BASS_StreamFree(currentStream);
    bass.BASS_StreamFree(nextStream);

    isPlaying = true;

    currentStream = loadMusicStream(filePath);
    nextStream = loadMusicStream(nextFilePath);
    // Pointer<Void> buf = nullptr;
    // bass.BASS_ChannelGetData(currentStream, buf, 1024);
    var err = bassMix.BASS_Mixer_StreamAddChannel(mainMixer, currentStream, 0);
    if (err == 0) {
      print(
          'BASS_Mixer_StreamAddChannel failed with error: ${bass.BASS_ErrorGetCode()}, mainMixer: $mainMixer, currentStream: $currentStream, nextStream: $nextStream');
    }


    // err = bass.BASS_ChannelPlay(mainMixer, 0);
    // if (err == 0) {
    //   print(
    //       'BASS_ChannelPlay failed with error: ${bass.BASS_ErrorGetCode()}, mainMixer: $mainMixer, currentStream: $currentStream, nextStream: $nextStream');
    // }
    // print('BASS failed with error: ${bass.BASS_ErrorGetCode()}');
    // var err2 = 0;
    // err2 = bassMix.BASS_Mixer_ChannelIsActive(mainMixer);
    // print('BASS_Mixer_ChannelIsActive failed with error: $err2');
    updateCurrentMusicState(index, musicList);
    _setCallback();
    startUpdatingPosition();
  }

  void updateCurrentMusicState(int index, String musicList) {
    var filePath = getPathByIndex(index, musicList);
    currentMusicList = musicList;
    currentMusicIndex = index;
    currentMusicInfo = getMusicInfoByPath(filePath);
    currentMusicPicture = Image.memory(
      getMusicImage(currentMusicInfo['artist']!, currentMusicInfo['album']!)!,
      fit: BoxFit.fill,
    );
    notifyListeners();

    ///保存到设置
    settings["currentMusicList"] = currentMusicList;
    settings["currentMusicIndex"] = currentMusicIndex;
    settings["currentMusicInfo"] = currentMusicInfo;
    saveJson(settings, settings["settingsPath"]);
  }

  int loadMusicStream(String filePath) {
    var filePathPtr = filePath.replaceAll('\\', '/').toNativeUtf16();
    var stream = bass.BASS_StreamCreateFile(
        0,
        filePathPtr.cast<Char>().cast<Void>(),
        0,
        0,
        BASS_UNICODE | BASS_STREAM_DECODE);
    if (stream == 0) {
      print(
          'BASS_StreamCreateFile failed with error: ${bass.BASS_ErrorGetCode()}');
    }

    return stream;
  }

  void playMusic(int index, String musicList) {
    if (currentStream == 0) {
      _playMusic(index: index, musicList: musicList);
    } else if (index == currentMusicIndex && musicList == currentMusicList) {
      startMusic();
    } else {
      _playMusic(index: index, musicList: musicList);
    }
  }

  void pauseMusic() {
    bass.BASS_ChannelPause(mainMixer);
    isPlaying = false;
    stopUpdatingPosition();
    notifyListeners();
  }

  void startMusic() {
    bass.BASS_ChannelStart(mainMixer);
    isPlaying = true;
    startUpdatingPosition();
    notifyListeners();
  }

  /// 主动调用
  void nextMusic() {
    // if (currentMusicList == "allMusic") {
    //   currentMusicIndex = (currentMusicIndex + 1) % allMusic.length;
    // }
    // if (playMode == 1) {
    //   startMusic();
    // } else {
    //   _playMusic(
    //       index: currentMusicIndex, musicList: currentMusicList);
    // }
    _playMusic(
        index: getIndexByMode(currentMusicIndex, 0, currentMusicList),
        musicList: currentMusicList);
  }

  void previousMusic() {
    if (currentMusicList == "allMusic") {
      currentMusicIndex =
          (currentMusicIndex - 1 + allMusic.length) % allMusic.length;
    }
    _playMusic(index: currentMusicIndex, musicList: currentMusicList);
  }

  void setPosition(double position) {
    if (currentStream == 0) return;
    currentPosition = position;
    // print('setPosition: $position');
    var positionInBytes =
        bass.BASS_ChannelSeconds2Bytes(currentStream, position);
    var o = bass.BASS_ChannelSetPosition(
        currentStream, positionInBytes, BASS_POS_BYTE);
    if (o != 0) {
      // print('BASS_ChannelSetPosition failed with error: ${bass.BASS_ErrorGetCode()}');
    }
  }

  void startUpdatingPosition() {
    // 每100毫秒调用一次updatePosition
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      updatePosition();
    });
  }

  void stopUpdatingPosition() {
    _timer?.cancel(); // 停止定时器
  }

  void updatePosition() {
    if (currentStream == 0) return;
    var positionInBytes =
        bass.BASS_ChannelGetPosition(currentStream, BASS_POS_BYTE);
    var positionInSeconds =
        bass.BASS_ChannelBytes2Seconds(currentStream, positionInBytes);
    currentPosition = positionInSeconds;
    notifyListeners();
  }

  void _setCallback() {
    var pro = NativeCallable<NativeCallback>.listener(_staticStopCallback);
    bass.BASS_ChannelSetSync(
        mainMixer, BASS_SYNC_END, 0, pro.nativeFunction, nullptr);
  }


  static void _staticStopCallback(
      int param1, int param2, int param3, Pointer<Void> param4) {
    _instance._stopCallback(param1, param2, param3, param4);
  }

  ///创建一个符合 Native 类型的 Dart 函数
  void _stopCallback(int param1, int param2, int param3, Pointer<Void> param4) {
    isPlaying = false;
    // start = DateTime.now();
    // nextMusic();
    bassMix.BASS_Mixer_StreamAddChannel(mainMixer, nextStream, bassmix.BASS_MIXER_CHAN_NORAMPIN);
    bassMix.BASS_Mixer_ChannelRemove(currentStream);
    // bass.BASS_ChannelPlay(mainMixer, 0);
    // stopUpdatingPosition(); 

    notifyListeners();
  }

  static void _staticWasapiInitCallback(Pointer<Void> buffer, int length, Pointer<Void> user){
    _instance._wasapiInitCallback(buffer, length, user);
  }

  int _wasapiInitCallback(Pointer<Void> buffer, int length, Pointer<Void> user){

    return 0;
  }
  // todo:实现获取高清图片的函数，并记录到变量中
}
