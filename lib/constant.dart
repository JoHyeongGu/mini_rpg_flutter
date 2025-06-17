import 'dart:ui';

import 'package:flutter/material.dart';

Color MAIN_COLOR = Color(0xff599256);
Color HOVER_COLOR = Color(0xff78c874);
Color CLICK_COLOR = Color(0xff377535);

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
  Color confirmColor = Colors.red,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: Text("Cancel"),
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
