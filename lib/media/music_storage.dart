import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

// 基类，保存最基本的信息
class MusicStorageBase {
  // 类的名称
  String name;
  // 封面数据
  Uint8List? coverImage;
  // 实例创建时间
  final DateTime creationTime;
  // 实例修改时间
  DateTime modificationTime;
  // 音乐文件路径列表
  List<String> musicFiles = [];
  // 逻辑删除的音乐文件列表
  List<String> deletedMusicFiles = [];
  // 新增：以专辑名和歌手名组合为键的封面缓存
  final Map<String, Uint8List?> albumArtistCoversCache = {};
  // 新增：存储音乐元数据的字典
  final Map<String, AudioMetadata> musicMetadataCache = {};
  // 新增：播放列表，存储音乐文件的索引
  List<int> playList = [];
  // 新增：显示列表，存储音乐文件的索引
  List<int> displayList = [];
  // 初始化每个音乐元数据时的回调
  void Function(String filePath, AudioMetadata? metaData)?
      onSingleMetadataInitialized;
  // 初始化完所有音乐元数据时的回调
  // void Function()? onAllMetadataInitialized;
  MusicStorageBase({
    this.name = 'Music.',
    this.coverImage,
    this.onSingleMetadataInitialized,
  })  : creationTime = DateTime.now(),
        modificationTime = DateTime.now();

  // 更新修改时间
  void _updateModificationTime() {
    modificationTime = DateTime.now();
  }

  // 设置封面
  void _setCoverImage(Uint8List imageData) {
    coverImage = imageData;
    _updateModificationTime();
  }

  // 从图片路径设置封面
  Future<void> setCoverFromImagePath(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final imageBytes = await imageFile.readAsBytes();
        _setCoverImage(imageBytes);
      } else {
        print('指定的图片文件不存在: $imagePath');
      }
    } catch (e) {
      print('读取图片文件时出错: $e');
    }
  }

  // 逻辑删除音乐文件
  void deleteMusic(String filePath) {
    if (musicFiles.contains(filePath)) {
      final index = musicFiles.indexOf(filePath);
      musicFiles.remove(filePath);
      deletedMusicFiles.add(filePath);
      // 从缓存中移除对应的封面和元数据
      albumArtistCoversCache.remove(filePath);
      musicMetadataCache.remove(filePath);
      // 从播放列表和显示列表中移除对应的索引
      playList.removeWhere((i) => i == index);
      displayList.removeWhere((i) => i == index);
      // 调整大于该索引的索引值
      playList = playList.map((i) => i > index ? i - 1 : i).toList();
      displayList = displayList.map((i) => i > index ? i - 1 : i).toList();
      _updateModificationTime();
    }
  }

  void deleteMusicByIndex(int index) {
    if (index >= 0 && index < musicFiles.length) {
      final filePath = musicFiles[index];
      deleteMusic(filePath);
    }
  }

  // 判断文件是否为音乐文件
  bool _isMusicFile(String filePath) {
    final lowerCasePath = filePath.toLowerCase();
    return lowerCasePath.endsWith('.mp3') ||
        lowerCasePath.endsWith('.flac') ||
        lowerCasePath.endsWith('.wav') ||
        lowerCasePath.endsWith('.aac') ||
        lowerCasePath.endsWith('.m4a') ||
        lowerCasePath.endsWith('.ogg') ||
        lowerCasePath.endsWith('.wma') ||
        lowerCasePath.endsWith('.aiff') ||
        lowerCasePath.endsWith('.dsd');
  }

  // 根据索引获取对应音乐文件的封面
  Future<Uint8List?> getCoverByIndex(int index) async {
    if (index < 0 || index >= musicFiles.length) {
      return null;
    }
    // 使用已有的接口获取元数据
    final metaData = await getMetadataByIndex(index);
    if (metaData == null) {
      return null;
    }
    final filePath = musicFiles[index];
    final albumArtistKey = _getCoversKey(metaData);
    if (metaData.album != null && metaData.artist != null) {
      if (albumArtistCoversCache.containsKey(albumArtistKey)) {
        return albumArtistCoversCache[albumArtistKey];
      }
    }
    // 如果缓存中没有，从元数据获取封面并更新缓存
    await initializeMetadata(filePath);
    return albumArtistCoversCache[albumArtistKey];
  }

  String _getCoversKey(AudioMetadata metaData) {
    if (metaData.album != null && metaData.artist != null) {
      final albumArtistKey = '${metaData.album}-${metaData.artist}';
      return albumArtistKey;
    }
    return '';
  }

  // 新增：根据索引获取对应音乐文件的元数据
  Future<AudioMetadata?> getMetadataByIndex(int index) async {
    if (index < 0 || index >= musicFiles.length) {
      return null;
    }
    final filePath = musicFiles[index];
    if (musicMetadataCache.containsKey(filePath)) {
      return musicMetadataCache[filePath];
    }
    try {
      await initializeMetadata(filePath);
      return musicMetadataCache[filePath];
    } catch (e) {
      print('getMetadataByIndex: Failed to read metadata: $e');
      return null;
    }
  }

  // 初始化所有元数据和封面
  Future<void> _initializeAllMetadataAndCovers() async {
    for (final filePath in musicFiles) {
      try {
        initializeMetadata(filePath);
      } catch (e) {
        print('initializeMetadataAndCovers: Failed to read metadata: $e');
      }
    }
  }

  Future<void> initializeMetadata(String filePath) async {
    try {
      final track = File(filePath);
      final metaData = readMetadata(track, getImage: false);
      musicMetadataCache[filePath] = metaData;
      if (metaData.album != null && metaData.artist != null) {
        final albumArtistKey = _getCoversKey(metaData);
        if (!albumArtistCoversCache.containsKey(albumArtistKey)) {
          // 缓存中没有封面，获取并添加到缓存
          final trackWithImage = File(filePath);
          final metaDataWithImage =
              readMetadata(trackWithImage, getImage: true);
          if (metaDataWithImage.pictures.isNotEmpty) {
            final cover = metaDataWithImage.pictures.first.bytes;
            albumArtistCoversCache[albumArtistKey] = cover;
          } else {
            albumArtistCoversCache[albumArtistKey] = null;
          }
        }
      }
      onSingleMetadataInitialized?.call(filePath, metaData);
    } catch (e) {
      print('getMetadata: Failed to read metadata: $e');
    }
  }
}

// 音乐文件夹类，继承自基类
class MusicFolderStorage extends MusicStorageBase {
  // 存储路径
  final String path;
  // 子路径的 MusicStorage 实例列表
  List<MusicFolderStorage> subStorages = [];
  // 创建子路径实例完毕后的回调函数
  void Function()? onSubStoragesCreated;
  MusicFolderStorage({
    required this.path,
    super.name,
    super.coverImage,
    super.onSingleMetadataInitialized,
    this.onSubStoragesCreated,
    List<String>? subPaths,
  }) {
    _readMusicFiles();
    _initializeAllMetadataAndCovers();
    if (subPaths != null) {
      _createSubStorages(subPaths);
    }
  }

  // 读取指定路径下的所有音乐文件
  void _readMusicFiles() {
    final directory = Directory(path);
    if (directory.existsSync()) {
      final entities = directory.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File && _isMusicFile(entity.path)) {
          musicFiles.add(entity.path);
        }
      }
    }
    // 初始化播放列表和显示列表
    playList = List.generate(musicFiles.length, (index) => index);
    displayList = List.generate(musicFiles.length, (index) => index);
    _updateModificationTime();
  }

  // 创建子路径的 MusicFolderStorage 实例
  void _createSubStorages(List<String> subPaths) {
    for (final subPath in subPaths) {
      final fullSubPath = '$path/$subPath';
      if (Directory(fullSubPath).existsSync()) {
        subStorages.add(MusicFolderStorage(path: fullSubPath));
      }
    }
    _updateModificationTime();
    // 调用回调函数
    onSubStoragesCreated?.call();
  }
}

// 新增：接收音乐路径列表的继承类
class MusicListStorage extends MusicStorageBase {
  MusicListStorage({
    required List<String> musicPaths,
    super.name,
    super.coverImage,
    super.onSingleMetadataInitialized,
  }) {
    _initializeWithMusicPaths(musicPaths);
    _initializeAllMetadataAndCovers();
  }

  void _initializeWithMusicPaths(List<String> musicPaths) {
    musicFiles = musicPaths;
    // 初始化播放列表和显示列表
    playList = List.generate(musicFiles.length, (index) => index);
    displayList = List.generate(musicFiles.length, (index) => index);
    _updateModificationTime();
  }
}
