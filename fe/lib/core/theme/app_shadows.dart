import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x0F14161A), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x1A14161A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x2914161A), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
