import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/auth/dangky.dart';
import 'package:shop_ban_dong_ho/features/auth/quenmatkhau.dart';
import 'package:shop_ban_dong_ho/features/home/trangchu.dart';
import 'package:shop_ban_dong_ho/main.dart';

class DangNhap extends StatefulWidget {
  const DangNhap({super.key});

  @override
  State<DangNhap> createState() => _DangNhapState();
}

class _DangNhapState extends State<DangNhap> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController taiKhoanController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  void dispose() {
    taiKhoanController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (_formKey.currentState!.validate()) {
      final email = taiKhoanController.text.trim();
      final password = passwordController.text.trim();

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Đăng nhập thành công
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MyButtonNavigationBar()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Lỗi đăng nhập';
        if (e.code == 'user-not-found') {
          message = 'Tài khoản không tồn tại';
        } else if (e.code == 'wrong-password') {
          message = 'Mật khẩu không đúng';
        } else {
          message = e.message ?? 'Lỗi không xác định';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // user cancel

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_ID_TOKEN',
          message: 'Missing Google ID Token',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) return;

      final email = user.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'ERROR_NO_EMAIL',
          message: 'User email is null',
        );
      }

      final check = await FirebaseFirestore.instance
          .collection('khachhang')
          .where('email', isEqualTo: email)
          .get();

      if (check.docs.isEmpty) {
        final docId = FirebaseFirestore.instance
            .collection('khachhang')
            .doc()
            .id;
        await FirebaseFirestore.instance
            .collection('khachhang')
            .doc(docId)
            .set({
              'id': docId,
              'hotenkh': user.displayName ?? 'Chưa có tên',
              'TaiKhoan': email,
              'matkhau': '',
              'gioitinh': 'Nam',
              'ngaysinh': '',
              'sdt': '',
              'diachi': '',
              'email': email,
            });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyButtonNavigationBar()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('FirebaseAuth lỗi: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập Google: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng nhập"),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Image.asset(
                  //   'assets/images/Logo.jpg',
                  //   height: 120,
                  //   width: 120,
                  // ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => signInWithGoogle(context),
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text("Đăng nhập với Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: taiKhoanController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _logIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DangKy()),
                      );
                    },
                    child: Text(
                      "Chưa có tài khoản? Đăng ký",
                      style: TextStyle(color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuenMatKhau()),
                      );
                    },
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
