import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/constant.dart';
import 'package:mini_rpg_flutter/login_page.dart';

import 'api_service.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  List<dynamic> _characterList = [];

  void loadData() async {
    _characterList = await getCharacterList(context);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MAIN_COLOR,
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(spacing: 30, children: [_title(), _characters()]),
      ),
    );
  }

  Widget _title() {
    return Text(
      "Select Character",
      style: TextStyle(
        fontSize: 40,
        fontFamily: 'pixel',
        color: Colors.white,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _characters() {
    return Column(
      children: [
        ..._characterList!.map(
          (d) => _characterCard(d as Map<String, dynamic>),
        ),
        CharacterCard(),
      ],
    );
  }

  Widget _characterCard(Map<String, dynamic> data) {
    return Container();
  }
}

class CharacterCard extends StatefulWidget {
  const CharacterCard({super.key});

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  String state = "";

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (details) {
        if (state != "hover") {
          setState(() {
            state = "hover";
          });
        }
      },
      onExit: (details) {
        if (state != "") {
          setState(() {
            state = "";
          });
        }
      },
      child: GestureDetector(
        onTapDown: (details) {
          if (state != "click") {
            setState(() {
              state = "click";
            });
          }
        },
        onTapUp: (details) {
          if (state != "hover") {
            showDialog(
              context: context,
              builder: (context) {
                return SelectClassPopup();
              },
            );
            setState(() {
              state = "hover";
            });
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width / 3,
          height: MediaQuery.of(context).size.height / 5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color:
                  state == "click"
                      ? CLICK_COLOR
                      : state == "hover"
                      ? HOVER_COLOR
                      : MAIN_COLOR,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                "ADD",
                style: TextStyle(
                  fontFamily: "pixel",
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectClassPopup extends StatefulWidget {
  const SelectClassPopup({super.key});

  @override
  State<SelectClassPopup> createState() => _SelectClassPopupState();
}

class _SelectClassPopupState extends State<SelectClassPopup> {
  Map<String, dynamic>? data;

  void loadData() async {
    data = await getClassList(context);
    setState(() {});
    print(data);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) return Center(child: CircularProgressIndicator());
    return Container(
      margin: EdgeInsets.symmetric(vertical: 100, horizontal: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}
