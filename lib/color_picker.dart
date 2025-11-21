import 'package:flutter/material.dart';

/// Basic color picker dialog
/// want to limit dependencies so the app is less dependent on other projects being maintained
/// initialColor should be an int in aRGB form. alpha channel is ignored
class ColorPickerDialog extends StatefulWidget {
  final int initialColor;

  const ColorPickerDialog({super.key, required this.initialColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late int r;
  late int g;
  late int b;

  @override
  void initState() {
    super.initState();
    final color = Color(widget.initialColor);
    r = (color.r * 255.0).round();
    g = (color.g * 255.0).round();
    b = (color.b * 255.0).round();
  }

  int get colorValue =>
      (0xFF << 24) | (r << 16) | (g << 8) | b; // ARGB int packed

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pick a Color"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: double.infinity,
            color: Color(colorValue),
          ),
          const SizedBox(height: 16),

          _slider("Red", r, Colors.red, (v) => setState(() => r = v)),
          _slider("Green", g, Colors.green, (v) => setState(() => g = v)),
          _slider("Blue", b, Colors.blue, (v) => setState(() => b = v)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, colorValue),
          child: const Text("OK"),
        ),
      ],
    );
  }

  Widget _slider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value.toDouble(),
            activeColor: color,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toString()),
        ),
      ],
    );
  }
}