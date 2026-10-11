// widgets/button_spinner.dart: маленький спиннер внутри кнопки на время запроса.
import 'package:flutter/material.dart';

class ButtonSpinner extends StatelessWidget {
  final double size;

  const ButtonSpinner({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
