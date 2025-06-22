import 'package:flutter/material.dart';

class Player extends StatefulWidget {
  Map<String, dynamic> data;
  Player(this.data, {super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        "assets/images/${widget.data["class"]["name"]}.png",
        width: 70,
      ),
    );
  }
}
