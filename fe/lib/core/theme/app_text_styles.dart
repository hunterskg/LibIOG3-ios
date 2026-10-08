import 'package:flutter/material.dart';

// ponytail: fontFamily khai báo tên 'Inter' / 'JetBrains Mono' (có qua
// package google_fonts khi chạy app); bundle font vào assets khi cần offline.
abstract final class AppTextStyles {
  static const _ui = 'Inter';
  static const _monoFamily = 'JetBrains Mono';

  static const display = TextStyle(
    fontFamily: _ui,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
  );
  static const h1 = TextStyle(
    fontFamily: _ui,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );
  static const h2 = TextStyle(
    fontFamily: _ui,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const h3 = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );
  static const bodySm = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
  );
  static const caption = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );
  static const mono = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );
}
