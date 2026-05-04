import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        padding: const EdgeInsets.all(12.0),
      );
    }
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: placeholder,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
    );
  }
}
