import 'package:flutter/material.dart';

/// A reusable label widget for form sections.
/// 
/// Uses the `labelMedium` text style from the current theme.
class AppLabel extends StatelessWidget {
  final String text;

  const AppLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
