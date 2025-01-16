import 'dart:convert';
import 'dart:io';

Map<String, dynamic> decodeJson(String jsonString){
    var result = jsonDecode(jsonString);
    return result;
}

Future<void> saveJson(Map<String, dynamic> data, String filePath)async{
  var jsonString = jsonEncode(data);
  File(filePath).writeAsStringSync(jsonString);
}



