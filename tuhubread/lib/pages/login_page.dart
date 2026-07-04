import 'package:flutter/material.dart';

import '../flavors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(F.title)),
      body: Center(child: Text('Hello ${F.title}')),
    );
  }
}
