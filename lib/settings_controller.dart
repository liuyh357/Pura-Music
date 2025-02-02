

class SettingsManager {
  // 静态的私有实例变量
  static SettingsManager? _instance;

  // 私有构造函数，防止外部直接实例化
  SettingsManager._();

  String language = 'zh';
  bool darkMode = false;
  

  // 静态的实例访问方法
  static SettingsManager get instance {
    _instance ??= SettingsManager._();
    return _instance!;
  }

}