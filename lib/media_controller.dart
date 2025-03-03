// 定义基本的播放模式，使用位掩码来表示
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;
import 'package:pura_music/util/file_utils.dart';
import 'bass_api/bass.dart';
// import 'bass_api/bass_fx.dart' as bassfx;
// import 'bass_api/bass_mix.dart' as bassmix;
// import 'bass_api/bass_wasapi.dart' as basswasapi;
import 'package:flutter/material.dart';

/// 定义 Native 函数类型
typedef NativeCallback = Void Function(UnsignedLong handle,
    UnsignedLong channel, UnsignedLong data, Pointer<Void> user);

/// 定义基本的播放模式，使用位掩码来表示
enum PlayMode {
  single(1), // 单次播放，二进制表示为 0001
  sequential(2), // 顺序播放，二进制表示为 0010
  random(4), // 随机播放，二进制表示为 0100
  loop(8); // 循环播放，二进制表示为 1000

  final int value;
  const PlayMode(this.value);
}

///用于管理播放模式组合的类，单例模式
class PlayModeManager {
  // 静态的私有实例变量
  static PlayModeManager? _instance;

  // 私有构造函数，防止外部直接实例化
  PlayModeManager._();

  // 静态的实例访问方法
  static PlayModeManager get instance {
    _instance ??= PlayModeManager._();
    return _instance!;
  }

  int _currentMode = 2;

  /// 添加一个或多个播放模式
  void addMode(PlayMode mode) {
    _currentMode |= mode.value;
  }

  /// 移除一个或多个播放模式
  void removeMode(PlayMode mode) {
    _currentMode &= ~mode.value;
  }

  /// 检查是否包含某个播放模式
  bool hasMode(PlayMode mode) {
    return (_currentMode & mode.value) != 0;
  }

  /// 获取当前组合的播放模式值
  int get currentModeValue => _currentMode;
}

/// 媒体控制中心
///
/// 基本模块：
///
///   播放控制
///
///     播放、暂停、播放模式（与音乐列表交互）、播放状态（是否暂停、进度）、切换歌曲（下一首，放到元数据中）
///
///   元数据
///
///     专辑封面、歌曲基本信息、歌词
///
///   音乐列表
///
///     基本列表：allMusic
///
///     自定义列表
///
///   均衡器
///
///   MV播放

class MediaController with ChangeNotifier {
  static MediaController? _instance;

  MediaController._() {
    _initMusicPlayer();
    loadDataFromJson('media_data.json');
    _loadImages('images');
  }

  static MediaController get instance {
    _instance ??= MediaController._();
    return _instance!;
  }

  Future<void> _loadImages(String path) async {
    if (!Directory(path).existsSync()) return;
    List<FileSystemEntity> files = Directory(path).listSync();
    for (FileSystemEntity file in files) {
      if (file is File && file.path.endsWith('.jpg')) {
        String key = file.path.split('\\').last.split('.').first;
        Uint8List imageData = file.readAsBytesSync();
        _musicImagesData[key] = imageData;
      }
    }
  }

  /// 从 JSON 字符串中解析数据并更新 MediaController 的状态
  Future<void> loadDataFromJson(String path) async {
    if (!File(path).existsSync()) return;
    String jsonString = File(path).readAsStringSync();
    Map<String, dynamic> data = jsonDecode(jsonString);

    // 更新播放模式
    playModeManager._currentMode = data['playMode'];

    // 更新播放状态
    _isPlaying = data['isPlaying'];

    // 更新当前播放位置
    _currentPosition = data['currentPosition'];

    // 更新音量
    _volume = data['volume'];

    // 更新当前音乐信息
    _currentMusicInfo = Map<String, String>.from(data['currentMusicInfo']);

    // 更新音乐图像数据
    // _musicImagesData = Map<String, Uint8List>.from(data['musicImagesData']);

    // 更新音乐信息
    _musicInfos = Map<String, Map<String, String>>.from(data['musicInfos']);

    // 更新所有音乐列表
    _allMusic = List<String>.from(data['allMusic']);

    // 更新文件夹音乐列表
    _folderMusicLists = List<(String, List<String>)>.from(
      data['folderMusicLists']
          .map((item) => (item[0], List<String>.from(item[1]))),
    );

    // 更新自定义音乐列表
    _customMusicLists = List<(String, List<String>)>.from(
      data['customMusicLists']
          .map((item) => (item[0], List<String>.from(item[1]))),
    );

    // 更新当前播放的音乐列表名称
    _currentPlayingMusicListName = data['currentMusicListName'];

    // 更新当前播放歌曲的索引
    _currentIndex = data['currentIndex'];

    // 更新音乐文件夹列表
    _musicFolders = List<String>.from(data['musicFolders']);
  }

  /// 将当前播放模式和其他相关数据保存为 JSON 格式
  Future<void> saveDataToJson() async {
    Map<String, dynamic> data = {
      'playMode': playModeManager.currentModeValue,
      'isPlaying': _isPlaying,
      'currentPosition': _currentPosition,
      'volume': _volume,
      'currentMusicInfo': _currentMusicInfo,
      // 'musicImagesData': _musicImagesData,
      'musicInfos': _musicInfos,
      'allMusic': _allMusic,
      'folderMusicLists': _folderMusicLists,
      'customMusicLists': _customMusicLists,
      'currentMusicListName': _currentPlayingMusicListName,
      'currentIndex': _currentIndex,
      'musicFolders': _musicFolders,
    };
    FileUtils.saveJson(data, 'media_data.json');
  }

  /// 播放控制

  ///播放状态相关变量
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  ///当前播放位置 [double] in seconds
  double _currentPosition = 0;
  double get currentPosition => _currentPosition;
  late Timer _timer;

  ///播放顺序
  List<int> _playOrder = [];
  List<int> get playOrder => _playOrder;

  ///播放模式相关变量
  PlayModeManager playModeManager = PlayModeManager.instance;

  ///音量相关变量
  double _volume = 1.0;
  double get volume => _volume;

  ///BASS库
  late bass_api _bass;

  int _currentMusicStream = 0;

  // 下一首歌曲的信息，放到元数据中

  /// 元数据

  //专辑封面：存储原图和压缩图，包括当前、下一首，以及存储所有压缩封面的map

  ///当前播放的音乐文件压缩专辑封面
  // Widget currentMusicImageCompressed = Image.asset(
  //   'assets/images/PuraMusicIcon1_square.png',
  //   fit: BoxFit.fill,
  // );

  ///当前播放的音乐文件原始专辑封面
  Widget currentMusicImage = Image.asset(
    'assets/images/PuraMusicIcon1_square.png',
    fit: BoxFit.fill,
  );

  ///当前播放的音乐文件信息
  Map<String, String> _currentMusicInfo = {
    "title": "unknown",
    "artist": "unknown",
    "album": "unknown",
    "duration": "1",
  };
  Map<String, String> get currentMusicInfo => _currentMusicInfo;

  ///用来存储压缩后的专辑封面，减少读取磁盘次数
  Map<String, Uint8List> _musicImagesData = {};
  Map<String, Uint8List> get musicImagesData => _musicImagesData;

  ///用来存储音乐文件信息
  Map<String, Map<String, String>> _musicInfos = {};
  Map<String, Map<String, String>> get musicInfos => _musicInfos;

  ///音乐列表

  ///基本列表：all music
  List<String> _allMusic = [];
  List<String> get allMusic => _allMusic;

  ///文件夹列表
  List<(String, List<String>)> _folderMusicLists = [];
  List<(String, List<String>)> get folderMusicLists => _folderMusicLists;

  ///自定义列表： list of （name，path）
  List<(String, List<String>)> _customMusicLists = [];
  List<(String, List<String>)> get customMusicLists => _customMusicLists;

  ///当前列表名字
  String _currentPlayingMusicListName = "unknow..."; //todo：后续要考虑重名的可能性
  String get currentPlayingMusicListName => _currentPlayingMusicListName;

  String _currentDisplayedMusicListName = 'allMusic';
  String get currentDisplayedMusicListName => _currentDisplayedMusicListName;
  set currentDisplayedMusicListName(String value) {
    _currentDisplayedMusicListName = value;
    notifyListeners();
  }

  ///当前播放的歌曲在列表中的索引
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  ///所有已添加的音乐文件夹
  List<String> _musicFolders = [];
  List<String> get musicFolders => _musicFolders;

  ///黑名单，优先级最高
  List<String> _fileBlackList = [];
  List<String> get fileBlackList => _fileBlackList;
  List<String> _folderBlackList = [];
  List<String> get folderBlackList => _folderBlackList;

  // 播放控制相关接口
  Future<void> _initMusicPlayer() async {
    var bassDy = DynamicLibrary.open('bass.dll');
    // var bassfxDy = DynamicLibrary.open('bass_fx.dll');
    // var bassmixDy = DynamicLibrary.open('bassmix.dll');
    // var basswasapiDy = DynamicLibrary.open('basswasapi.dll');
    _bass = bass_api(bassDy);
    // bassFx = bassfx.bass_fx_api(bassfxDy);
    // bassMix = bassmix.bass_mix_api(bassmixDy);
    // bassWasapi = basswasapi.bass_wasapi_api(basswasapiDy);

    // var version = bassFx.BASS_FX_GetVersion();
    // print('BASS_FX version: $version');

    // version = bassMix.BASS_Mixer_GetVersion();
    // print('BASS_Mixer version: $version');

    // 设置设备流的缓冲区大小
    // bass.BASS_SetConfig(BASS_CONFIG_DEV_BUFFER, 30); // 毫秒

    if (_bass.BASS_Init(-1, 44100, 0, nullptr, nullptr) == 0) {
      print('BASS_Init failed with error: ${_bass.BASS_ErrorGetCode()}');
      return;
    }
    // mainMixer = bassMix.BASS_Mixer_StreamCreate(
    //     44100, 2, BASS_STREAM_DECODE | bassmix.BASS_MIXER_QUEUE);
    // if (mainMixer == 0) {
    //   print(
    //       'BASS_Mixer_StreamCreate failed with error: ${bass.BASS_ErrorGetCode()}');
    //   return;
    // }
    // if(bassWasapi.BASS_WASAPI_Init(-1, 44100, 0, 0, 0.03, 0, nullptr, nullptr) == 0){
    //   print('BASS_WASAPI_Init failed with error: ${bass.BASS_ErrorGetCode()}');
    // }
    // var path = '$currentDir\\silence.mp3';
    // var pathPtr = path.replaceAll('\\', '/').toNativeUtf16();
    // silenceStream = bass.BASS_StreamCreateFile(
    //     0, pathPtr.cast<Char>().cast<Void>(), 0, 0, BASS_UNICODE);
    // bass.BASS_ChannelPlay(silenceStream, 1);
    _loadPlugin('bassflac');
    _loadPlugin('bassopus');
    // loadPlugin('bass_fx');
    _loadPlugin('bassdsd');
    // loadPlugin('bassmix');
    _loadPlugin('basswv');
    _loadPlugin('basscd');
  }

  Future<void> _loadPlugin(String pluginName) async {
    var pluginPath = '$pluginName.dll';
    var pluginHandle = _bass.BASS_PluginLoad(
        pluginPath.toNativeUtf16().cast<Char>(), BASS_UNICODE);
    if (pluginHandle == 0) {
      print(
          'Failed to load $pluginName plugin with error: ${_bass.BASS_ErrorGetCode()}');
    } else {
      print('$pluginName plugin loaded successfully!');
    }
  }

  void _setCallback() {
    var stopSync = NativeCallable<NativeCallback>.listener(_staticStopCallback);
    var startSync =
        NativeCallable<NativeCallback>.listener(_staticStartCallback);
    _bass.BASS_ChannelSetSync(_currentMusicStream, BASS_SYNC_END, 0,
        stopSync.nativeFunction, nullptr);
    _bass.BASS_ChannelSetSync(_currentMusicStream, BASS_SYNC_SETPOS, 0,
        startSync.nativeFunction, nullptr);
  }

  static void _staticStopCallback(
      int handle, int channel, int data, Pointer<Void> user) {
    _instance?._stopCallback();
  }

  void _stopCallback() {
    _isPlaying = false;
    next();
    _stopUpdatingPosition();
    notifyListeners();
  }

  static void _staticStartCallback(
      int handle, int channel, int data, Pointer<Void> user) {
    _instance?._startCallback();
  }

  void _startCallback() {
    _bass.BASS_ChannelSetAttribute(_currentMusicStream, BASS_ATTRIB_VOL, 0);
    _bass.BASS_ChannelSlideAttribute(
        _currentMusicStream, BASS_ATTRIB_VOL, _volume, 20);
    //todo:可能需要添加一小段延迟？
  }

//todo: 更改播放列表或者更改播放模式或添加歌曲后要更新播放列表 [ playOrder ]
  void changePlayingList() {
    if (_currentDisplayedMusicListName != _currentPlayingMusicListName) {
      _currentPlayingMusicListName = _currentDisplayedMusicListName;
      generatePlayOrder();
    }
  }

  ///只能由前端（用户端）改变播放列表
  //todo:index需要根据列表来更改，并且要取模，只在一个地方这样做，其他地方不需要根据列表更改
  void play(int index, {bool replay = false}) {
    int newIndex = _playOrder[index % _playOrder.length];
    if (newIndex == _currentIndex && !replay) {
      _start();
      return;
    }
    updateCurrentMusicInfo(newIndex);
    String path = getPathByIndex(newIndex);
    _freeMusicStream();
    _currentMusicStream = _loadMusicStream(path);
    _isPlaying = true;
    _setCallback();
    _bass.BASS_ChannelSetPosition(_currentMusicStream, 0, BASS_POS_BYTE);
    var err = _bass.BASS_ChannelPlay(_currentMusicStream, 0);
    if (err == 0) {
      print(
          'BASS_ChannelPlay failed with error: ${_bass.BASS_ErrorGetCode()}, _currentMusicStream: $_currentMusicStream');
    }
  }

  void pause() {
    _bass.BASS_ChannelPause(_currentMusicStream);
    _isPlaying = false;
    _stopUpdatingPosition();
    notifyListeners();
  }

  void _start() {
    _bass.BASS_ChannelStart(_currentMusicStream);
    _isPlaying = true;
    _startUpdatingPosition();
    notifyListeners();
  }

  ///需要针对单曲循环做处理
  void next() {}
  void previous() {}
  void setPosition(double position) {
    if (_currentMusicStream == 0) return;
    _currentPosition = position;
    // print('setPosition: $position');
    var positionInBytes =
        _bass.BASS_ChannelSeconds2Bytes(_currentMusicStream, position);
    var err = _bass.BASS_ChannelSetPosition(
        _currentMusicStream, positionInBytes, BASS_POS_BYTE);
    if (err != 0) {
      // print('BASS_ChannelSetPosition failed with error: ${bass.BASS_ErrorGetCode()}');
    }
  }

  void _startUpdatingPosition() {
    // 每100毫秒调用一次updatePosition
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updatePosition();
    });
  }

  void _stopUpdatingPosition() {
    _timer.cancel(); // 停止定时器
  }

  void _updatePosition() {
    if (_currentMusicStream == 0) return;
    var positionInBytes =
        _bass.BASS_ChannelGetPosition(_currentMusicStream, BASS_POS_BYTE);
    var positionInSeconds =
        _bass.BASS_ChannelBytes2Seconds(_currentMusicStream, positionInBytes);
    _currentPosition = positionInSeconds;
    notifyListeners();
  }

  // 音量控制相关接口
  void setVolume(double newVolume) {}

  void updateCurrentMusicInfo(int index) {
    _currentIndex = index;
    _currentPlayingMusicListName = _currentDisplayedMusicListName;
    _currentMusicInfo = _musicInfos[_allMusic[index]]!;
    // var key = _getKey(_currentMusicInfo['artist']!, _currentMusicInfo['album']!);
    // if (_musicImagesData.containsKey(key)) {
    //   currentMusicImageCompressed = Image.memory(_musicImagesData[key]!);
    // } else {
    //   currentMusicImageCompressed = Image.asset(
    //     'assets/images/PuraMusicIcon1_square.png',
    //     fit: BoxFit.fill,
    //   );
    // }
    currentMusicImage = Image.memory(getMusicImage(index));
    // notifyListeners();
  }

  int _loadMusicStream(String filePath) {
    var filePathPtr = filePath.toNativeUtf16();
    var stream = _bass.BASS_StreamCreateFile(
        0, filePathPtr.cast<Char>().cast<Void>(), 0, 0, BASS_UNICODE);
    if (stream == 0) {
      print(
          'BASS_StreamCreateFile failed with error: ${_bass.BASS_ErrorGetCode()}');
    }

    return stream;
  }

  void _freeMusicStream() {
    _bass.BASS_StreamFree(_currentMusicStream);
    _currentMusicStream = 0;
  }

  ///元数据相关接口
  Future<Map<String, String>> getMusicInfo(
      {required String filePath, bool getImage = false}) async {
    // 获取音乐文件的信息
    final track = File(filePath);
    final metaData = readMetadata(track, getImage: getImage);
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
    _musicInfos[filePath] = info;
    if (getImage) {
      String folderPath = 'images';
      if (!Directory(folderPath).existsSync()) {
        Directory(folderPath).createSync();
      }

      var key = _getKey(info['artist']!, info['album']!);
      String imagePath = '$folderPath\\$key.jpg';
      if (!File(imagePath).existsSync()) {
        if (metaData.pictures.isNotEmpty) {
          /// 保存专辑封面略缩图到images文件夹
          // var file = File(imagePath);

          var image = img.decodeImage(metaData.pictures.first.bytes);
          var resizedImageBytes = img.copyResize(image!, width: 400);
          var jpegBytes = img.encodeJpg(resizedImageBytes);
          File(imagePath).writeAsBytesSync(jpegBytes);
          _musicImagesData[key] = jpegBytes;
        } else {
          _musicImagesData[key] =
              File('assets\\images\\PuraMusicIcon1_square.png')
                  .readAsBytesSync();
        }
      }
    }
    return info;
  }

  Uint8List getMusicImageCompressed(String artist, String album) {
    var key = _getKey(artist, album);
    if (!_musicImagesData.containsKey(key)) {
      _musicImagesData[key] =
          File('assets\\images\\PuraMusicIcon1_square.png').readAsBytesSync();
    }
    return _musicImagesData[key]!;
  }

  ///根据当前播放的index来获取高清封面图
  Uint8List getMusicImage(int index) {
    final track = File(getPathByIndex(index));
    final metaData = readMetadata(track, getImage: true);
    if (metaData.pictures.isNotEmpty) {
      return metaData.pictures.first.bytes;
    } else {
      return File('assets\\images\\PuraMusicIcon1_square.png')
          .readAsBytesSync();
    }
  }

  Future<Map<String, String>> getMusicInfoByPath(String path) async {
    if (_musicInfos.containsKey(path)) {
      return _musicInfos[path]!;
    } else {
      // print("musicInfos not contain $path");
      return await getMusicInfo(filePath: path, getImage: true);
    }
  }

  ///从当前显示的列表获取路径，而不是从当前播放的列表中获取路径
  String getPathByIndex(int index) {
    if (_currentDisplayedMusicListName == 'allMusic') {
      return _allMusic[index];
    } else {
      return _customMusicLists
          .firstWhere((element) => element.$1 == _currentDisplayedMusicListName)
          .$2[index];
    }
  }

  List<String> getDisplayedMusicList() {
    if (_currentDisplayedMusicListName == 'allMusic') {
      return _allMusic;
    } else {
      return _folderMusicLists
          .firstWhere((element) => element.$1 == _currentDisplayedMusicListName,
              orElse: () {
        return _customMusicLists.firstWhere(
            (element) => element.$1 == _currentDisplayedMusicListName,
            orElse: () {
          return ('', []);
        });
      }).$2;
    }
  }

  // 音乐列表管理相关接口
  bool containsMusicFile(String filePath) {
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

  void addMusicFolder(String path) {
    if (Directory(path).existsSync() &&
        !_musicFolders.contains(path) &&
        containsMusicFile(path)) {
      _musicFolders.add(path);
      for (var file in Directory(path).listSync()) {
        if (!file.existsSync()) continue;
        if (isMusicFile(file.path)) {
          addMusic(file.path, path.split('\\').last);
        }
      }
      notifyListeners();
    }
  }

  ///添加歌曲调用的默认函数，会添加到allMusic和文件夹歌单中
  Future<void> addMusic(String filePath, String folderName) async {
    if (!isMusicFile(filePath)) {
      return;
    }
    if (!_allMusic.contains(filePath)) {
      _allMusic.add(filePath);
    }
    for (var list in _folderMusicLists) {
      if (list.$1 == folderName) {
        if (!list.$2.contains(filePath)) {
          list.$2.add(filePath);
        }
        return;
      }
    }
    _folderMusicLists.add((folderName, [filePath]));
  }

  ///只用来添加歌曲到自定义歌单中
  Future<void> addMusicToMusiclist(String path, String musicListName) async {
    if (!isMusicFile(path)) {
      return;
    }
    for (var list in _customMusicLists) {
      if (list.$1 == musicListName) {
        if (!list.$2.contains(path)) {
          list.$2.add(path);
        }
        notifyListeners();
        return;
      }
    }
    _customMusicLists.add((musicListName, [path]));
    notifyListeners();
  }

  ///移除文件夹以及文件夹下所有歌曲，不包含子文件夹
  Future<void> removeMusicFolder(String path) async {
    if (_musicFolders.contains(path)) {
      _musicFolders.remove(path);
      for (var file in Directory(path).listSync()) {
        if (!file.existsSync()) continue;
        if (isMusicFile(file.path)) {
          removeMusic(file.path);
        }
      }
      notifyListeners();
    }
  }

  //todo 从全部歌曲或文件夹列表中删除的歌曲会加入到黑名单中，防止再次读取
  ///从所有列表中删除歌曲
  Future<void> removeMusic(String path) async {
    if (_allMusic.contains(path)) {
      _allMusic.remove(path);
    }
    for (var list in _folderMusicLists) {
      if (list.$2.contains(path)) {
        list.$2.remove(path);
      }
    }
    for (var list in _customMusicLists) {
      if (list.$2.contains(path)) {
        list.$2.remove(path);
      }
    }
  }

  void removeMusicFromPlaylist(int index) {}

  ///根据播放模式生成播放顺序列表的函数
  void generatePlayOrder(int index) {
    var musicPaths = getDisplayedMusicList();
    int musicCount = musicPaths.length;
    if (musicCount == 0) return;

    if (playModeManager.hasMode(PlayMode.sequential)) {
      _playOrder = List.generate(musicCount, (index_) => index_);
    } else if (playModeManager.hasMode(PlayMode.random)) {
      _playOrder = List.generate(musicCount, (index_) => index_);
      _playOrder.shuffle();
      for (int i = 0; i < _playOrder.length; i++) {
        if (_playOrder[i] == index) {
          _playOrder[i] = _playOrder[index];
          _playOrder[index] = index;
        }
      }
    } else if (playModeManager.hasMode(PlayMode.single)) {
      _playOrder = [index];
    }
    _currentIndex = _playOrder[index%_playOrder.length];
  }

  /// 获取key
  String _getKey(String artist, String album) {
    return "${_sanitizeFileName(artist)}-${_sanitizeFileName(album)}";
  }

  ///去除文件名中的不合法字符
  String _sanitizeFileName(String fileName) {
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
}
