import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/auth/doimatkhau.dart';

class QuenMatKhau extends StatefulWidget {
  const QuenMatKhau({super.key});

  @override
  State<QuenMatKhau> createState() => _QuenMatKhauState();
}

class _QuenMatKhauState extends State<QuenMatKhau> {
  final TextEditingController _taiKhoanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _checkTaiKhoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String taiKhoan = _taiKhoanController.text.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('khachhang')
          .where('TaiKhoan', isEqualTo: taiKhoan)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final userId = userDoc.id;
        final email = userDoc['email'];

        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Xác nhận'),
            content: Text(
              'Tài khoản $taiKhoan được tìm thấy với email $email.\nBạn có muốn đổi mật khẩu không?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Đồng ý')),
            ],
          ),
        );

        if (confirm == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DoiMatKhau(userId: userId)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy tài khoản với tên này.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi, thử lại sau.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _taiKhoanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quên mật khẩu"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Nhập tài khoản của bạn để đổi mật khẩu",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _taiKhoanController,
                decoration: InputDecoration(
                  labelText: "Tài khoản",
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập tài khoản';
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkTaiKhoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("TIẾP TỤC", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
