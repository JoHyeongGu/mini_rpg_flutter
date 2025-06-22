import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/constant.dart';
import 'package:mini_rpg_flutter/world_page.dart';

import 'api_service.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  List<dynamic> _characterList = [];

  Future<void> loadData() async {
    _characterList = await getCharacterList(context);
    setState(() {});
  }

  Future<void> reload() async {
    await loadData();
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
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            child: SingleChildScrollView(
              child: Column(spacing: 30, children: [_title(), _characters()]),
            ),
          ),
          IconButton(
            onPressed: () {
              showConfirm(
                context,
                callFn: () => logout(context),
                title: "Logout",
                text: "Are you sure want to Logout?",
                confirmText: "Logout",
                icon: Icons.logout,
              );
            },
            icon: Icon(Icons.logout_sharp, color: Colors.white),
            iconSize: 30,
          ),
        ],
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
      spacing: 30,
      children: [
        ..._characterList.map((d) => CharacterCard(data: d, reload: reload)),
        CharacterCard(reload: reload),
      ],
    );
  }
}

class CharacterCard extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Future<void> Function()? reload;
  const CharacterCard({super.key, this.data, this.reload});

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  String state = "";

  Color get borderColor {
    if (widget.data != null && widget.data!.containsKey("class_color")) {
      String _color = widget.data!["class_color"];
      return _color.toColor();
    }
    return Colors.white;
  }

  void _delete() async {
    await deleteCharacter(context, widget.data!["char_id"]);
    if (widget.reload != null) widget.reload!();
  }

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
            if (widget.data == null) {
              showDialog(
                context: context,
                builder: (context) {
                  return SelectClassPopup(widget.reload!);
                },
              );
            } else {
              selectCharacter(context, widget.data?["char_id"]);
              gotoPage(
                context,
                WorldPage(charId: widget.data?["char_id"]),
                500,
              );
            }
            setState(() {
              state = "hover";
            });
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width / 3,
          height: MediaQuery.of(context).size.height / 5,
          decoration: BoxDecoration(
            color: borderColor,
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
            child: _contents(),
          ),
        ),
      ),
    );
  }

  Widget _contents() {
    if (widget.data == null || widget.data!.isEmpty) {
      return Center(
        child: Text(
          "ADD",
          style: TextStyle(
            fontFamily: "pixel",
            fontSize: 50,
            color: Colors.white,
          ),
        ),
      );
    }
    TextStyle _style = TextStyle(
      fontFamily: "pixel",
      fontSize: 25,
      color: Colors.white,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data!["nickname"],
                  style: _style.copyWith(fontSize: 45),
                ),
                Row(
                  spacing: 15,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(widget.data!["class_name"], style: _style),
                    Icon(
                      widget.data!["gender"] == "none"
                          ? Icons.person
                          : widget.data!["gender"] == "male"
                          ? Icons.male
                          : Icons.female,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                showConfirm(
                  context,
                  callFn: _delete,
                  title: "Delete Character",
                  text: "Are you sure you want to delete this character?",
                  confirmText: "Delete",
                  icon: Icons.delete,
                );
              },
              icon: Icon(Icons.delete_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectClassPopup extends StatefulWidget {
  final Future<void> Function() reload;
  const SelectClassPopup(this.reload, {super.key});

  @override
  State<SelectClassPopup> createState() => _SelectClassPopupState();
}

class _SelectClassPopupState extends State<SelectClassPopup> {
  late TextEditingController nameController;
  Map<String, dynamic>? classData;
  Map<String, dynamic> charData = {};
  String? includeId;
  TextStyle style = TextStyle(fontFamily: 'pixel');

  void loadData() async {
    classData = await getClassList(context);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (classData == null) return Center(child: CircularProgressIndicator());
    if (charData.isEmpty) charData["gender"] = "none";
    return Container(
      margin: EdgeInsets.symmetric(vertical: 100, horizontal: 80),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _title(),
          if (charData.keys.contains("class_id")) _infoInput() else _cardList(),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (includeId != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  if (charData.keys.contains("class_id")) {
                    setState(() {
                      charData.clear();
                    });
                  } else {
                    setState(() {
                      includeId = null;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                  child: Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
              ),
            ),
          Spacer(),
          Text(
            "Select Class",
            style: TextStyle(
              fontFamily: "pixel",
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _cardList() {
    List<Widget> rowList;
    if (includeId == null) {
      rowList =
          classData!.entries.map((MapEntry entry) {
            return _card(entry.value, id: entry.key);
          }).toList();
    } else {
      rowList =
          classData![includeId]["child"].map<Widget>((d) => _card(d)).toList();
    }
    return Expanded(child: Row(spacing: 20, children: rowList));
  }

  Widget _card(Map<String, dynamic> d, {String? id}) {
    String name = d["name"];
    String color = d["color"];
    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: color.toColor(),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              if (id != null) {
                setState(() {
                  includeId = id;
                });
              } else {
                setState(() {
                  charData["class_id"] = d["id"];
                });
              }
            },
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'pixel',
                  fontSize: 30,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 0),
                      // blurRadius: 1,
                    ),
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 0),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoInput() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 30,
          children: [
            _input(nameController, "Character's Name"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 15,
              children: [
                _genderBtn("none"),
                _genderBtn("male"),
                _genderBtn("female"),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                charData["nickname"] = nameController.text;
                if (await createCharacter(context, charData)) {
                  await widget.reload();
                  Navigator.pop(context);
                }
              },
              child: Text(
                "Create",
                style: TextStyle(
                  fontFamily: "pixel",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool hide = false,
    Function(String)? callFn,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 30,
        width: 300,
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
      ),
    );
  }

  Widget _genderBtn(String key) {
    Color normalColor = Color(0xffdadada);
    Color activeColor = Color(0xffffea90);
    switch (key) {
      case "male":
        activeColor = Color(0xff5470ff);
        break;
      case "female":
        activeColor = Color(0xffff5454);
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: charData["gender"] == key ? activeColor : normalColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap:
              () => setState(() {
                charData["gender"] = key;
              }),
          child: Padding(
            padding: EdgeInsets.all(25),
            child:
                key == "none"
                    ? Text(
                      "None",
                      style: style.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 20,
                        color: Colors.black.withAlpha(120),
                      ),
                    )
                    : Icon(key == "male" ? Icons.male : Icons.female),
          ),
        ),
      ),
    );
  }
}
