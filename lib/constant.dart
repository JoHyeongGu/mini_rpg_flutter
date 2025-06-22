import 'dart:ui';

import 'package:flutter/material.dart';

Color MAIN_COLOR = Color(0xff599256);
Color HOVER_COLOR = Color(0xff78c874);
Color CLICK_COLOR = Color(0xff377535);

double MAP_WIDTH = 3000;
double MAP_HEIGHT = 3000;

extension ColorExtension on String {
  toColor() {
    var hexString = "ff$this";
    final buffer = StringBuffer();
    buffer.write(hexString.replaceFirst('0x', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

void showConfirm(
  BuildContext context, {
  required Function callFn,
  required String title,
  required String text,
  required String confirmText,
  IconData? icon,
  Color confirmColor = Colors.red,
}) {
  Color _color = Colors.black.withAlpha(160);
  TextStyle textStyle = TextStyle(fontFamily: "pixel", color: _color);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          spacing: 10,
          children: [
            if (icon != null) Icon(icon, color: _color, size: 40),
            Text(title),
          ],
        ),
        titleTextStyle: textStyle.copyWith(fontSize: 35),
        content: Text(text),
        contentTextStyle: textStyle.copyWith(fontSize: 17),
        backgroundColor: Colors.white.withAlpha(170),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: Text(
              "Cancel",
              style: textStyle.copyWith(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              callFn();
            },
            child: Text(confirmText, style: TextStyle(color: confirmColor)),
          ),
        ],
      );
    },
  );
}
