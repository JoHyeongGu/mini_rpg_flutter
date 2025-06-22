import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/api_service.dart';
import 'package:mini_rpg_flutter/constant.dart';

import 'character_page.dart';
import 'world_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [Background(), LoginContents()]));
  }
}

class Background extends StatefulWidget {
  const Background({super.key});

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: MAIN_COLOR,
          width: double.infinity,
          height: double.infinity,
        ),
      ],
    );
  }
}

class LoginContents extends StatefulWidget {
  const LoginContents({super.key});

  @override
  State<LoginContents> createState() => _LoginContentsState();
}

class _LoginContentsState extends State<LoginContents> {
  String section = "";
  TextStyle style = TextStyle(fontFamily: 'pixel', color: Colors.white);
  late TextEditingController idController;
  late TextEditingController pwdController;
  late TextEditingController emailController;

  void startSection() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      section = "login";
    });
  }

  @override
  void initState() {
    super.initState();
    idController = TextEditingController();
    pwdController = TextEditingController();
    emailController = TextEditingController();
    startSection();
  }

  @override
  void dispose() {
    idController.dispose();
    pwdController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Game DB Modeling",
            style: style.copyWith(fontSize: 15, letterSpacing: 5),
          ),
          Text("MiniRPG with MySQL", style: style.copyWith(fontSize: 40)),
          SizedBox(height: 30),
          contents("login", loginSection(), 120),
          contents("register", registerSection(), 230),
        ],
      ),
    );
  }

  void _login(String input) async {
    Map<String, dynamic>? result = await login(
      context,
      idController.text,
      pwdController.text,
    );
    if (result != null) {
      if (result["last_char"] == null) {
        gotoPage(context, CharacterPage(), 100);
      } else {
        gotoPage(context, WorldPage(charId: result["last_char"]), 100);
      }
    }
  }

  Widget contents(String _section, Widget child, double height) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(top: section == _section ? 15 : 0),
      height: section == _section ? height : 0,
      width: 370,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: child,
      ),
    );
  }

  Widget loginSection() {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 15,
          children: [
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 15,
                children: [
                  inputContainer(idController, "Id or Email", callFn: _login),
                  inputContainer(
                    pwdController,
                    "Password",
                    callFn: _login,
                    hide: true,
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  _login("");
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 40),
                  minimumSize: Size(200, 85),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Icon(Icons.lock_outline, color: MAIN_COLOR, size: 40),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              "Don't you have account?",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            TextButton(
              onPressed:
                  () => setState(() {
                    idController.clear();
                    pwdController.clear();
                    section = "register";
                  }),
              child: Text(
                "Register New Account",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget registerSection() {
    return Column(
      spacing: 15,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed:
              () => setState(() {
                idController.clear();
                pwdController.clear();
                emailController.clear();
                section = "login";
              }),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          iconSize: 20,
        ),
        inputContainer(idController, "Input New ID"),
        inputContainer(emailController, "Input New Email"),
        inputContainer(pwdController, "Input New Password", hide: true),
        ElevatedButton(
          onPressed: () async {
            if (await register(
              context,
              idController.text,
              emailController.text,
              pwdController.text,
            )) {
              setState(() {
                idController.clear();
                pwdController.clear();
                emailController.clear();
                section = "login";
              });
            }
          },
          child: Text("Register"),
        ),
      ],
    );
  }

  Widget inputContainer(
    TextEditingController controller,
    String hint, {
    bool hide = false,
    Function(String)? callFn,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: hide,
        onSubmitted: callFn,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.only(top: 7, left: 15, right: 15),
          hintText: hint,
          hintStyle: style.copyWith(
            fontSize: 15,
            color: Colors.grey.withAlpha(150),
          ),
        ),
        style: style.copyWith(
          fontSize: 15,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
