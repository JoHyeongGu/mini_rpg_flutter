import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/constant.dart';
import 'package:mini_rpg_flutter/login_page.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

final dio = Dio();
final cookieJar = CookieJar();

void gotoPage(BuildContext context, Widget target, int ms) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => target,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: Duration(milliseconds: ms),
    ),
  );
}

void setupDio() {
  dio.interceptors.add(CookieManager(cookieJar));
  dio.options.baseUrl = 'http://127.0.0.1:5000';
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.black.withAlpha(150),
    ),
  );
}

Future<Response?> sendRequest(
  BuildContext context,
  Future<Response<dynamic>> Function() requestFn,
) async {
  try {
    final response = await requestFn();
    if (!response.statusCode.toString().startsWith("2")) {
      showToast(
        context,
        "${response.statusCode} | ${response.data.toString()}",
      );
    }
    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      showToast(
        context,
        "${e.response?.realUri.path} ${e.response?.statusCode} | ${e.response?.data.toString() ?? "No Response"}",
      );
    } else {
      showToast(
        context,
        "${e.response?.realUri.path} ${e.response?.statusCode} | ${e.message ?? "Connect Error"}",
      );
    }
  } catch (e) {
    showToast(context, e.toString());
  }
  return null;
}

Future<bool> register(
  BuildContext context,
  String id,
  String email,
  String pwd,
) async {
  Map<String, String> data = {"user_id": id, "email": email, "password": pwd};
  var response = await sendRequest(
    context,
    () => dio.post(
      '/register',
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
  if (response == null) {
    return false;
  } else {
    return response.statusCode.toString().startsWith("2");
  }
}

Future<Map<String, dynamic>?> login(
  BuildContext context,
  String id,
  String pwd,
) async {
  Map<String, String> data = {"user_id": id, "password": pwd};
  final response = await sendRequest(
    context,
    () => dio.post(
      '/login',
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
  if (response != null && response.statusCode == 200) {
    return response.data;
  } else {
    return null;
  }
}

Future<bool> selectCharacter(BuildContext context, int id) async {
  var response = await sendRequest(context, () => dio.patch('/login/char/$id'));
  await addNewPlayerPosition(context, id);
  if (response == null) {
    return false;
  } else {
    showToast(context, "Complete to update User last access field!");
    return response.statusCode.toString().startsWith("2");
  }
}

Future<void> logout(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/logout'));

  if (response != null && response.statusCode == 200) {
    gotoPage(context, LoginPage(), 100);
  }
}

Future<Map<String, dynamic>> getClassList(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/class/all'));
  return response?.data;
}

Future<Map<String, dynamic>> getClassData(BuildContext context, int id) async {
  Map<String, dynamic> data;
  var response = await sendRequest(context, () => dio.get('/class/$id'));
  data = response?.data["data"];
  if (data.keys.contains("open_flag")) {
    data.remove("open_flag");
  }
  response = await sendRequest(
    context,
    () => dio.get('/class/skills/${data["class_id"]}'),
  );
  data["skills"] = response?.data["data"];
  for (Map<String, dynamic> skill in data["skills"]) {
    skill.removeWhere((key, value) => value == 0);
  }
  return data;
}

Future<List<dynamic>> getCharacterList(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/characters'));
  return response?.data["data"];
}

Future<Map<String, dynamic>> getCharacterInfo(
  BuildContext context,
  int id,
) async {
  String path = '/character/detail/$id';
  final response = await sendRequest(context, () => dio.get(path));
  return response?.data["data"];
}

Future<bool> createCharacter(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  var response = await sendRequest(
    context,
    () => dio.post(
      '/character/create',
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
  if (response == null) {
    return false;
  } else {
    return response.statusCode.toString().startsWith("2");
  }
}

Future<bool> deleteCharacter(BuildContext context, int id) async {
  var response = await sendRequest(context, () => dio.delete('/character/$id'));
  if (response == null) {
    return false;
  } else {
    return response.statusCode.toString().startsWith("2");
  }
}

Future<Map<int, int>> getMaxExpData(
  BuildContext context,
  int id,
  int include,
) async {
  Map<int, int> result = {};
  var response = await sendRequest(context, () => dio.get('/exp/$include'));
  for (var data in response?.data) {
    result[data["level"]] = data["exp"];
  }
  response = await sendRequest(context, () => dio.get('/exp/$id'));
  for (var data in response?.data) {
    result[data["level"]] = data["exp"];
  }
  return result;
}

Future<Map<String, dynamic>> getWorldData(BuildContext context, int id) async {
  final response = await sendRequest(context, () => dio.get('/world/all/$id'));
  return response?.data;
}

Future<void> addNewPlayerPosition(BuildContext context, int id) async {
  var response = await sendRequest(context, () => dio.get('/world/player/$id'));
  if (response?.data == null || (response?.data as Map).isEmpty) {
    double xPos = (MAP_WIDTH / 2) - MediaQuery.of(context).size.width / 2;
    double yPos = (MAP_HEIGHT / 2) - MediaQuery.of(context).size.height / 2;
    var data = {"id": id, "x": xPos, "y": yPos};
    response = await sendRequest(
      context,
      () => dio.post(
        '/world/player_add',
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      ),
    );
  }
}

Future<void> saveUserData(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  // save position data
  var parameter = {
    "id": data["character"]["char_id"],
    "x": data["world"]["player"]["x_pos"],
    "y": data["world"]["player"]["y_pos"],
  };
  var response = await sendRequest(
    context,
    () => dio.patch(
      '/world/update',
      data: parameter,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
  // save character data
  response = await sendRequest(
    context,
    () => dio.patch(
      '/character/update',
      data: data["character"],
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
}

Future<List<dynamic>> getShopData(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/shop'));
  return response?.data;
}

Future<List<dynamic>> getInventoryData(BuildContext context, int charId) async {
  final response = await sendRequest(
    context,
    () => dio.get('/inventory/$charId'),
  );
  return response?.data;
}

Future<bool> buyItem(
  BuildContext context,
  int charId,
  int itemId,
  int count,
) async {
  Map<String, int> data = {
    "char_id": charId,
    "item_id": itemId,
    "count": count,
  };
  var response = await sendRequest(
    context,
    () => dio.post(
      '/buy',
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );
  if (response != null && response.statusCode.toString().startsWith("2")) {
    showToast(context, "Success to buy Item!");
    return true;
  } else {
    return false;
  }
}

Future<Map<String, dynamic>> getQuest(BuildContext context, int id) async {
  final response = await sendRequest(context, () => dio.get('/quest/$id'));
  return response?.data;
}

Future<List<dynamic>> getAcceptQuests(BuildContext context, int charId) async {
  final response = await sendRequest(
    context,
    () => dio.get('/quest/accept/all/$charId'),
  );
  return response?.data;
}

Future<void> acceptQuest(BuildContext context, int charId, int questId) async {
  var parameter = {"char_id": charId, "quest_id": questId};
  var response = await sendRequest(
    context,
    () => dio.post(
      '/quest/accept',
      data: parameter,
      options: Options(contentType: Headers.jsonContentType),
    ),
  );

  if (response != null && response.statusCode.toString().startsWith("2")) {
    showToast(context, "Accept Quest!");
  }
}
