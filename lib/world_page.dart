import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_rpg_flutter/api_service.dart';
import 'package:mini_rpg_flutter/character_page.dart';
import 'package:mini_rpg_flutter/constant.dart';
import 'package:mini_rpg_flutter/inventory.dart';
import 'package:mini_rpg_flutter/login_page.dart';
import 'package:mini_rpg_flutter/player.dart';

class WorldPage extends StatefulWidget {
  final int charId;
  const WorldPage({super.key, required this.charId});

  @override
  State<WorldPage> createState() => _WorldPageState();
}

class _WorldPageState extends State<WorldPage> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Map<String, dynamic> data = {};
  bool loading = true;
  bool visible = false;
  bool onSkillDialog = false;
  bool onSkillEffect = false;
  String selectedSkill = "";
  List<Offset> coins = [];

  double scrollStep = 10;
  Timer? _moveTimer;
  final Set<LogicalKeyboardKey> _keysPressed = {};

  void loadData() async {
    data["character"] = await getCharacterInfo(context, widget.charId);
    data["class"] = await getClassData(context, data["character"]["class_id"]);
    data["maxExp"] = await getMaxExpData(
      context,
      data["class"]["class_id"],
      data["class"]["include_class"],
    );
    data["world"] = await getWorldData(context, data["character"]["char_id"]);
    data["acceptQuest"] = await getAcceptQuests(context, widget.charId);
    setState(() {
      scrollStep = data["character"]["speed"].toDouble() / 3.5;
      loading = false;
      for (int i = 0; i < 10; i++) {
        _spawnRandomItem();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _initPosition();
    });
  }

  void save() {
    saveUserData(context, data);
  }

  @override
  void initState() {
    super.initState();
    loadData();
    _turnOn();
    Timer.periodic(Duration(seconds: 2), (_) => _spawnRandomItem());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _initPosition() {
    _horizontalController.jumpTo(data["world"]["player"]["x_pos"].toDouble());
    _verticalController.jumpTo(data["world"]["player"]["y_pos"].toDouble());
  }

  void _spawnRandomItem() {
    if (coins.length > 50) return;
    double coinSize = 50;
    final random = Random();
    double x = random.nextDouble() * (MAP_WIDTH - coinSize);
    double y = random.nextDouble() * (MAP_HEIGHT - coinSize);
    setState(() {
      coins.add(Offset(x, y)); // Offset 객체로 추가
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      switch (key) {
        case LogicalKeyboardKey.escape:
          _stopMovingIfNoKeys();
          showDialog(context: context, builder: (_) => SettingUI(save: save));
          break;
        case LogicalKeyboardKey.keyE:
          _stopMovingIfNoKeys();
          showDialog(context: context, builder: (_) => Inventory(data));
          break;
        case LogicalKeyboardKey.digit1:
          _activeSkill(0);
          break;
        case LogicalKeyboardKey.digit2:
          _activeSkill(1);
          break;
        case LogicalKeyboardKey.digit3:
          _activeSkill(2);
          break;
        case LogicalKeyboardKey.keyW:
        case LogicalKeyboardKey.keyA:
        case LogicalKeyboardKey.keyS:
        case LogicalKeyboardKey.keyD:
          _keysPressed.add(key);
          _startMoving();
          break;
      }
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(key);
      _stopMovingIfNoKeys();
    }
  }

  void _startMoving() {
    _moveTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      _moveCamera();
    });
  }

  void _stopMovingIfNoKeys() {
    if (_keysPressed.isEmpty) {
      _moveTimer?.cancel();
      _moveTimer = null;
    }
  }

  void _moveCamera() {
    double dx = 0;
    double dy = 0;

    if (_keysPressed.contains(LogicalKeyboardKey.keyW)) dy -= scrollStep;
    if (_keysPressed.contains(LogicalKeyboardKey.keyS)) dy += scrollStep;
    if (_keysPressed.contains(LogicalKeyboardKey.keyA)) dx -= scrollStep;
    if (_keysPressed.contains(LogicalKeyboardKey.keyD)) dx += scrollStep;

    if (dx != 0 || dy != 0) {
      _horizontalController.jumpTo(
        (_horizontalController.offset + dx).clamp(
          0.0,
          _horizontalController.position.maxScrollExtent,
        ),
      );
      _verticalController.jumpTo(
        (_verticalController.offset + dy).clamp(
          0.0,
          _verticalController.position.maxScrollExtent,
        ),
      );
      data["world"]["player"]["x_pos"] = _horizontalController.offset;
      data["world"]["player"]["y_pos"] = _verticalController.offset;

      _checkCollision();
    }
  }

  void _checkCollision() async {
    double playerSize = 100;

    setState(() {
      coins.removeWhere((itemPos) {
        final bool collided =
            (itemPos -
                    Offset(
                      data["world"]["player"]["x_pos"],
                      data["world"]["player"]["y_pos"],
                    ))
                .distance <
            (playerSize / 2);
        if (collided) {
          data["character"]["exp"] += 120;
          data["character"]["coin"] += 10;
        }
        return collided;
      });
    });

    for (var npc in data["world"]["npc"]) {
      double distance =
          (Offset(npc["x_pos"].toDouble(), npc["y_pos"].toDouble()) -
                  Offset(
                    data["world"]["player"]["x_pos"],
                    data["world"]["player"]["y_pos"],
                  ))
              .distance;
      final bool collided = distance <= playerSize * 2;
      if (data["focusNpc"] == null && collided) {
        Map<String, dynamic> quest = await getQuest(context, npc["npc_id"]);
        setState(() {
          data["focusNpc"] = {...npc, ...quest};
        });
      }
      if (data["focusNpc"] != null) {
        distance =
            (Offset(
                      data["focusNpc"]["x_pos"].toDouble(),
                      data["focusNpc"]["y_pos"].toDouble(),
                    ) -
                    Offset(
                      data["world"]["player"]["x_pos"],
                      data["world"]["player"]["y_pos"],
                    ))
                .distance;
        final bool goodbye = distance > playerSize * 2;
        if (goodbye) {
          setState(() {
            data["focusNpc"] = null;
          });
        }
      }
    }
  }

  void _activeSkill(int index) async {
    if (data["character"]["level"] + 10 <
        data["class"]["skills"][index]["level"]) {
      return;
    }
    setState(() {
      selectedSkill = data["class"]["skills"][index]["name"];
      selectedSkill =
          '${"${selectedSkill}!!".substring(0, 5)}\n${"${selectedSkill}!!".substring(5)}';
      onSkillDialog = true;
      onSkillEffect = true;
    });
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      onSkillEffect = false;
    });
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      onSkillDialog = false;
    });
  }

  void _turnOn() async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      visible = true;
    });
  }

  Positioned _shadow() {
    return Positioned(
      top: MediaQuery.of(context).size.height / 2 + 27,
      left: MediaQuery.of(context).size.width / 2 - 35,
      child: Container(
        width: 70,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(300),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xff336536),
        body: Stack(
          children: [
            _buildWorld(),
            _skillEffect(),
            _shadow(),
            Player(data),
            _skillDialog(),
            UIContents(data),
            _questDialog(),
            _acceptQuests(),
            IgnorePointer(
              child: AnimatedContainer(
                duration: Duration(seconds: 2),
                color: Colors.white.withAlpha(visible ? 0 : 255),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorld() {
    return SingleChildScrollView(
      controller: _verticalController,
      physics: const NeverScrollableScrollPhysics(),
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          width: MAP_WIDTH,
          height: MAP_HEIGHT,
          margin: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height / 2 - 30,
            horizontal: MediaQuery.of(context).size.width / 2 - 30,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  "assets/images/grass_map.png",
                  fit: BoxFit.cover,
                  width: MAP_WIDTH,
                  height: MAP_HEIGHT,
                ),
              ),
              ...coins.map(
                (pos) => Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: Image.asset(
                    "assets/images/coin.png",
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              ...(data["world"]["npc"] as List<dynamic>).map(
                (npc) => Positioned(
                  left: npc["x_pos"].toDouble(),
                  top: npc["y_pos"].toDouble(),
                  child: Image.asset(
                    "assets/images/${npc["entity_img"]}",
                    width: 150,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skillEffect() {
    String _color = data["class"]["color"];
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.bounceInOut,
      top: MediaQuery.of(context).size.height / 2 - (onSkillEffect ? 10 : -20),
      left: MediaQuery.of(context).size.width / 2 - (onSkillEffect ? 100 : 30),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.bounceInOut,
        decoration: BoxDecoration(
          color: _color.toColor().withAlpha(onSkillEffect ? 100 : 0),
          borderRadius: BorderRadius.circular(300),
        ),
        width: onSkillEffect ? 200 : 0,
        height: onSkillEffect ? 70 : 0,
      ),
    );
  }

  Widget _skillDialog() {
    return Positioned(
      top: MediaQuery.of(context).size.height / 2 - 120,
      left: MediaQuery.of(context).size.width / 2 - 15,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 500),
        opacity: onSkillDialog ? 1 : 0,
        child: Stack(
          children: [
            Image.asset("assets/images/dialog.png", width: 110),
            Positioned(
              top: 25,
              left: 20,
              child: Text(
                selectedSkill,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "pixel",
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questDialog() {
    return IgnorePointer(
      ignoring: data["focusNpc"] == null,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: data["focusNpc"] == null ? 0 : 1,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              if (data["focusNpc"] != null)
                Positioned(
                  right: 0,
                  child: Image.asset(
                    "assets/images/${data["focusNpc"]["detail_img"]}",
                    width: 450,
                  ),
                ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(170),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        data["focusNpc"] != null
                            ? [
                              Text(
                                data["focusNpc"]["name"],
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: "pixel",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                data["focusNpc"]["npc_talk"],
                                style: TextStyle(
                                  fontSize: 30,
                                  fontFamily: "pixel",
                                ),
                              ),
                              Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      acceptQuest(
                                        context,
                                        data["character"]["char_id"],
                                        data["focusNpc"]["quest_id"],
                                      );
                                      data["acceptQuest"] =
                                          await getAcceptQuests(
                                            context,
                                            widget.charId,
                                          );
                                    },
                                    child: Text(
                                      "Accept",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                            : [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acceptQuests() {
    if (data["acceptQuest"] == null ||
        (data["acceptQuest"] as List<dynamic>).isEmpty)
      return Container();
    return Positioned(
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(170),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(15),
        margin: EdgeInsets.all(10),
        child: Column(
          children:
              (data["acceptQuest"] as List<dynamic>)
                  .map(
                    (quest) => Text(
                      "Get ${quest["need_count"]} Coins | Reward: ${quest["reward_coin"]} coin, ${quest["reward_exp"]} exp",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class UIContents extends StatefulWidget {
  final Map<String, dynamic> data;
  const UIContents(this.data, {super.key});

  @override
  State<UIContents> createState() => _UIContentsState();
}

class _UIContentsState extends State<UIContents> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _status()),
        Positioned(bottom: 0, right: 0, child: _skill()),
      ],
    );
  }

  Widget _status() {
    int hp = widget.data["character"]["hp"];
    int maxHp = widget.data["character"]["max_hp"];
    int level = widget.data["character"]["level"];
    int exp = widget.data["character"]["exp"];
    late int maxExp;
    for (MapEntry entry in (widget.data["maxExp"] as Map<int, int>).entries) {
      if (level < entry.key) break;
      maxExp = entry.value;
    }
    double hpRatio = hp / maxHp;
    double expRatio = exp / maxExp;
    if (expRatio >= 1) {
      widget.data["character"]["level"]++;
      widget.data["character"]["exp"] = 0;
      saveUserData(context, widget.data);
    }
    TextStyle textStyle = TextStyle(
      fontSize: 30,
      fontFamily: "pixel",
      color: Colors.white,
    );
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBar(hpRatio, color: Colors.red, txt: "$hp / $maxHp"),
          _statusBar(expRatio, color: Colors.yellow, txtSize: 7),
          Row(
            spacing: 7,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("LV.${widget.data["character"]["level"]}", style: textStyle),
              SizedBox(width: 20),
              Image.asset("assets/images/coin.png", width: 30),
              Text("${widget.data["character"]["coin"]}", style: textStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBar(
    double value, {
    required Color color,
    String txt = "",
    double txtSize = 15,
    double width = 300,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(160),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: width * value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              txt,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "pixel",
                fontSize: txtSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _skill() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 10,
        children:
            (widget.data["class"]["skills"] as List)
                .asMap()
                .entries
                .map<Widget>((entry) => _skillCard(entry.value, entry.key))
                .toList(),
      ),
    );
  }

  Widget _skillCard(Map<String, dynamic> skill, int index) {
    bool active = widget.data["character"]["level"] + 10 >= skill["level"];
    TextStyle textStyle = TextStyle(
      fontFamily: "pixel",
      color: Colors.white.withAlpha(active ? 200 : 100),
      fontSize: 15,
    );
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(active ? 170 : 100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text("Lv.${skill["level"]}", style: textStyle.copyWith(fontSize: 13)),
          Text(skill["name"], style: textStyle),
          Text(
            "[ PRESS ${index + 1} ]",
            style: textStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingUI extends StatefulWidget {
  Function save;
  SettingUI({super.key, required this.save});

  @override
  State<SettingUI> createState() => _SettingUIState();
}

class _SettingUIState extends State<SettingUI> {
  TextStyle textStyle = TextStyle(
    fontFamily: "pixel",
    color: Colors.black.withAlpha(200),
  );

  void _backToCharacterSelect() {
    widget.save();
    gotoPage(context, CharacterPage(), 100);
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    widget.save();
    await Future.delayed(Duration(milliseconds: 500));
    await logout(context);
    Navigator.of(context).pop();
    gotoPage(context, LoginPage(), 200);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withAlpha(130),
      title: Text("Menu"),
      titleTextStyle: textStyle.copyWith(fontSize: 30),
      contentTextStyle: textStyle,
      content: Container(
        height: 120,
        child: Column(
          spacing: 15,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _button(
              "Back to Character Select",
              icon: Icons.people,
              callFn: _backToCharacterSelect,
            ),
            _button("Logout", icon: Icons.logout, callFn: _logout),
          ],
        ),
      ),
    );
  }

  Widget _button(String txt, {IconData? icon, GestureTapCallback? callFn}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: callFn,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            spacing: 10,
            children: [
              if (icon != null) Icon(icon),
              Text(txt, style: textStyle.copyWith(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
