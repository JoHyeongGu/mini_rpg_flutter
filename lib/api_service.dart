import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/character_page.dart';

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
    SnackBar(content: Text(message), duration: Duration(seconds: 5)),
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
        "${e.response?.statusCode} | ${e.response?.data.toString() ?? "No Response"}",
      );
    } else {
      showToast(
        context,
        "${e.response?.statusCode} | ${e.message ?? "Connect Error"}",
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

Future<void> login(BuildContext context, String id, String pwd) async {
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
    gotoPage(context, CharacterPage(), 100);
  }
}

Future<List<dynamic>> getCharacterList(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/characters'));
  return response?.data["data"];
}

Future<Map<String, dynamic>> getClassList(BuildContext context) async {
  final response = await sendRequest(context, () => dio.get('/class/all'));
  return response?.data;
}
