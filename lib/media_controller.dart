// 定义基本的播放模式，使用位掩码来表示
import 'dart:math';

// 定义基本的播放模式，使用位掩码来表示
enum PlayMode {
  single(1), // 单次播放，二进制表示为 0001
  sequential(2), // 顺序播放，二进制表示为 0010
  random(4), // 随机播放，二进制表示为 0100
  loop(8); // 循环播放，二进制表示为 1000

  final int value;
  const PlayMode(this.value);
}

// 用于管理播放模式组合的类，单例模式
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

  int _currentMode = 0;

  // 添加一个或多个播放模式
  void addMode(PlayMode mode) {
    _currentMode |= mode.value;
  }

  // 移除一个或多个播放模式
  void removeMode(PlayMode mode) {
    _currentMode &= ~mode.value;
  }

  // 检查是否包含某个播放模式
  bool hasMode(PlayMode mode) {
    return (_currentMode & mode.value) != 0;
  }

  // 获取当前组合的播放模式值
  int get currentModeValue => _currentMode;
}

class MediaController {
  static MediaController? _instance;

  MediaController._();

  static MediaController get instance {
    _instance ??= MediaController._();

    return _instance!;
  }

  // 播放状态相关变量
  bool isPlaying = false;
  bool isPaused = false;

  // 播放进度相关变量
  Duration currentPosition = Duration.zero;
  Duration duration = Duration.zero;

  // 播放模式相关变量
  PlayModeManager playModeManager = PlayModeManager.instance;

  // 音量相关变量
  double volume = 1.0;

  // 媒体资源相关变量
  String? currentMediaUrl;
  String currentMusicList = "allMusic";

  // 音乐列表
  List<String> musicList = [];
  int currentIndex = 0;

  // 播放控制相关接口
  void play() {}
  void pause() {}
  void stop() {}
  void seek(Duration position) {}

  // 播放模式相关接口
  void setPlayMode(PlayMode mode) {}

  // 音量控制相关接口
  void setVolume(double newVolume) {}

  // 状态查询相关接口
  Duration getDuration() {
    return Duration.zero;
  }

  Duration getCurrentPosition() {
    return Duration.zero;
  }

  bool isMusicPlaying() {
    return false;
  }

  // 媒体加载相关接口
  void load(String url) {}

  // 音乐列表管理相关接口
  void addMusicToPlaylist(String url) {}
  void removeMusicFromPlaylist(int index) {}
  void clearPlaylist() {}
  void playNext() {}
  void playPrevious() {}
  void playAtIndex(int index) {}

  // 根据播放模式生成播放顺序列表的函数
  List<int> generatePlayOrder(List<String> musicPaths) {
    int musicCount = musicPaths.length;
    List<int> playOrder = [];
    var playMode = PlayModeManager.instance;
    if (playMode.hasMode(PlayMode.sequential)) {
      playOrder = List.generate(musicCount, (index) => index);
    } else if (playMode.hasMode(PlayMode.random)) {
      List<int> orderedList = List.generate(musicCount, (index) => index);
      orderedList.shuffle(Random());
    } else if (playMode.hasMode(PlayMode.single)) {
      playOrder = [currentIndex];
    }


    return playOrder;
  }
}
