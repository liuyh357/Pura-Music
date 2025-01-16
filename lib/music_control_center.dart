class MusicControlCenter {
  static MusicControlCenter? _instance;

  MusicControlCenter._();

  static MusicControlCenter get instance {
    _instance ??= MusicControlCenter._();

    return _instance!;
  }
  
}
