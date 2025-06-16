import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorldPage extends StatefulWidget {
  const WorldPage({super.key});

  @override
  State<WorldPage> createState() => _WorldPageState();
}

class _WorldPageState extends State<WorldPage> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final double scrollStep = 10;
  Timer? _moveTimer;
  final Set<LogicalKeyboardKey> _keysPressed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _centerCamera();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _centerCamera() {
    _horizontalController.jumpTo(1500 - MediaQuery.of(context).size.width / 2);
    _verticalController.jumpTo(1500 - MediaQuery.of(context).size.height / 2);
  }

  void _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      _keysPressed.add(key);
      _startMoving();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xff336536),
        body: Stack(children: [_buildWorld(), _buildPlayer(), UIContents()]),
      ),
    );
  }

  Widget _buildPlayer() {
    return const Center(child: Text("🙂", style: TextStyle(fontSize: 50)));
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
          width: 3000,
          height: 3000,
          margin: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height / 2 - 30,
            horizontal: MediaQuery.of(context).size.width / 2 - 30,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              "assets/images/grass_map.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class UIContents extends StatefulWidget {
  const UIContents({super.key});

  @override
  State<UIContents> createState() => _UIContentsState();
}

class _UIContentsState extends State<UIContents> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [Positioned(top: 0, left: 0, child: _status())]);
  }

  Widget _status() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        spacing: 10,
        children: [_statusBar(Colors.red), _statusBar(Colors.blue)],
      ),
    );
  }

  Widget _statusBar(Color _color) {
    double width = 150;
    double height = 15;
    return Container(
      color: Colors.white.withAlpha(160),
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(color: _color, width: width * 0.2),
      ),
    );
  }
}
