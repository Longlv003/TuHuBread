import 'package:flutter/material.dart';

/// Ảnh nền chung của app (hoạ tiết kem/cam nhạt).
///
/// Bọc bên ngoài [Scaffold] và để `Scaffold.backgroundColor` là trong suốt,
/// nhờ vậy nền trải kín cả phần dưới thanh điều hướng và vùng safe area,
/// không bị cắt ngang.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/app_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
