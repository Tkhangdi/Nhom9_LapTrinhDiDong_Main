import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_ban_dong_ho/features/auth/dangnhap.dart';

Future<void> checkLoginStatus(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DangNhap()),
      );
    });
  }
}
