import 'package:flutter/material.dart';

class SearchTheme {
  // Colors
  static const Color surfaceColor = Color(0x33000000); // Semi-transparent black
  static const Color chipColor = Color(0x26FFFFFF);    // Semi-transparent white
  static const Color cardColor = Color(0x26FFFFFF);    // Semi-transparent white

  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFAAAAAA);

  // Per your exception, using transparent to let the dynamic background show through
  static const Color backgroundColor = Colors.transparent;

  // Typography
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: primaryText,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );

  static const TextStyle topCardTitleStyle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );

  static const TextStyle chipTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: primaryText,
  );
}

