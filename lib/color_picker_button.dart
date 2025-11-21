import 'package:flutter/material.dart';

Widget colorPickerButton({
  required Color background,
  required Color border,
  required VoidCallback onPressed,
  BorderRadiusGeometry borderRadius = BorderRadius.zero,
  double size = 24,
  double padding = 5,
}) {
  return Padding(
    padding: EdgeInsetsGeometry.all(padding),
    child: SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(width: 1, color: border),
          )
        ),
        onPressed: onPressed,
        child: null,
      )
    )
  );
}