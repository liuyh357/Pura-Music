import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pura_music/media_controller.dart';
import 'package:win32/win32.dart';

/// 包含文件的添加、删除等操作
class FileUtils {
  static MediaController mediaController = MediaController.instance;
  static Future<(String, bool)?> pickFolder(BuildContext context) {
    var str = showDialog<(String, bool)>(
      context: context,
      builder: (BuildContext context) {
        return const FolderPickerDialog();
      },
    );
    return str;
  }

  static Future<Map<String, dynamic>> decodeJson(String jsonString) async {
    var result = jsonDecode(jsonString);
    return result;
  }

  static Future<void> saveJson(
      Map<String, dynamic> data, String filePath) async {
    var jsonString = jsonEncode(data);
    File(filePath).writeAsStringSync(jsonString);
  }

  static void addFolder(
      {required String path, bool withSubFolders = true, bool save = true}) {
    mediaController.addMusicFolder(path);

    if (withSubFolders) {
      for (var fileEntity in Directory(path).listSync()) {
        if (Directory(fileEntity.path).existsSync()) {
          addFolder(path: fileEntity.path, withSubFolders: true, save: false);
        }
      }
    }
    if (save) {
      mediaController.saveDataToJson();
    }
  }
  static void deleteFolder({required String path, bool withSubFolder = false, bool save = true}) {
    mediaController.removeMusicFolder(path);
    if (withSubFolder) {
      for (var fileEntity in Directory(path).listSync()) {
        if (Directory(fileEntity.path).existsSync()) {
          deleteFolder(path: fileEntity.path, withSubFolder: true, save: false);
        }
      }
    }
    if (save) {
      mediaController.saveDataToJson();
    }
  }
}

class FolderPickerDialog extends StatefulWidget {
  const FolderPickerDialog({super.key});

  @override
  _FolderPickerDialogState createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  String _currentPath = '\\';
  late Future<List<FileSystemEntity>> _filesFuture;
  List<String> _drives = [];
  bool _isRoot = true;
  bool _withSubFolders = true;

  @override
  void initState() {
    super.initState();
    _filesFuture = _getFilesAndFolders(_currentPath);
    _drives = _getWindowsDrives();
  }

  static List<String> _getWindowsDrives() {
    final logicalDrives = GetLogicalDrives();
    final drives = <String>[];

    for (var i = 0; i < 26; i++) {
      if ((logicalDrives & (1 << i)) != 0) {
        final driveLetter = String.fromCharCode(65 + i);
        drives.add('$driveLetter:\\');
      }
    }

    return drives;
  }

  Future<List<FileSystemEntity>> _getFilesAndFolders(
      String directoryPath) async {
    final directory = Directory(directoryPath);
    List<FileSystemEntity> entities = [];

    try {
      if (directoryPath == '\\') {
        entities = await directory
            .list()
            .where((entity) => entity is Directory)
            .toList();
      } else {
        entities = await directory.list().toList();
      }

      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
    } catch (e) {
      print('Error reading directory: $e');
    }

    return entities;
  }

  void _updatePath(String newPath) {
    setState(() {
      _currentPath = newPath;
      _filesFuture = _getFilesAndFolders(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // backgroundColor: Colors.transparent,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              if (!_drives.contains(_currentPath)) {
                _updatePath(path.dirname(_currentPath));
              } else {
                setState(() {
                  _isRoot = true;
                  _currentPath = "";
                });
              }
            },
            icon: const Icon(Icons.arrow_upward),
            tooltip: "上级目录",
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择文件夹',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(
                  width: 500,
                  child: Text(
                    '当前路径：$_currentPath',
                    style: const TextStyle(fontSize: 10),
                  ))
            ],
          ),
        ],
      ),
      titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: _isRoot
                  ? ListView.builder(
                      itemCount: _drives.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                            height: 25,
                            width: 280,
                            child: InkWell(
                              onTap: () {
                                _updatePath(_drives[index]);
                                _isRoot = false;
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.folder),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 500,
                                    child: Text(
                                      _drives[index],
                                      style: const TextStyle(
                                          overflow: TextOverflow.fade),
                                    ),
                                  ),
                                ],
                              ),
                            ));
                      })
                  : FutureBuilder<List<FileSystemEntity>>(
                      future: _filesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('当前目录下没有文件或文件夹'));
                        } else {
                          return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final file = snapshot.data![index];
                                final fileName = path.basename(file.path);
                                return SizedBox(
                                    height: 25,
                                    width: 280,
                                    child: InkWell(
                                      onTap: () {
                                        if (file is Directory) {
                                          _updatePath(file.path);
                                        } else {
                                          // Navigator.of(context).pop(file.path);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          file is Directory
                                              ? const Icon(Icons.folder)
                                              : const Icon(
                                                  Icons.insert_drive_file),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 500,
                                            child: Text(
                                              fileName,
                                              style: const TextStyle(
                                                  overflow: TextOverflow.fade),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ));
                              });
                        }
                      },
                    ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        if (!_isRoot)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '包含子文件夹：',
                style: TextStyle(fontSize: 14),
              ),
              Switch(
                  value: _withSubFolders,
                  onChanged: (val) {
                    setState(() => _withSubFolders = val);
                  }),
            ],
          ),
        if (!_isRoot)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop((_currentPath, _withSubFolders));
            },
            child: const Text('确定'),
          ),
        TextButton(
          child: const Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
