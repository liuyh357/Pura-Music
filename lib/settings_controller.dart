import 'dart:convert';
import 'dart:io';

Map<String, dynamic> decodeJson(String jsonString){
    var result = jsonDecode(jsonString);
    return result;
}

void saveJson(Map<String, dynamic> data, String filePath){
  var jsonString = jsonEncode(data);
  File(filePath).writeAsStringSync(jsonString);
}



