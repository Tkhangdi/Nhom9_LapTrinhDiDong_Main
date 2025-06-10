import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shop_ban_dong_ho/features/auth/dangnhap.dart';
import 'package:shop_ban_dong_ho/features/notifications/thongbao.dart';
import 'package:shop_ban_dong_ho/features/orders/quanlydonhang.dart';
import 'package:shop_ban_dong_ho/features/profile/thongtinnguoidung.dart';

void main() {
  runApp(Info());
}

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _getUserData(),
        builder: (context, snapshot) {
          // Hiển thị loading khi đang tải dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Xử lý lỗi
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          
          // Lấy dữ liệu người dùng
          String avatarUrl = 'assets/images/default.png';
          String userName = 'Người dùng';
          
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
            avatarUrl = userData['avatarUrl'] ?? 'assets/images/default.png';
            userName = userData['hotenkh'] ?? 'Người dùng';
          }
          
          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _getAvatarImage(avatarUrl),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      buildMenuItem(
                        context,
                        icon: Icons.person_outline,
                        text: "My Account",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyAccountScreen(),
                            ),
                          );
                        },
                      ),
                      buildMenuItem(
                        context,
                        icon: Icons.person_outline,
                        text: "Quản lý sản phẩm",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuanLyDonHangScreen(),
                            ),
                          );
                        },
                      ),
                      buildMenuItem(
                        context,
                        icon: Icons.notifications_outlined,
                        text: "Notifications",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      buildMenuItem(
                        context,
                        icon: Icons.settings,
                        text: "Settings",
                      ),
                      buildMenuItem(
                        context,
                        icon: Icons.help_outline,
                        text: "Help Center",
                      ),
                      buildMenuItem(
                        context,
                        icon: Icons.logout,
                        text: "Log Out",
                        color: Colors.red,
                        onTap: ()async
                        {
                           await FirebaseAuth.instance.signOut();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  await googleSignIn.signOut();
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const DangNhap()),
  );

                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // Hàm lấy dữ liệu người dùng từ Firestore
  Future<DocumentSnapshot> _getUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      return await FirebaseFirestore.instance
          .collection('khachhang')
          .doc(currentUser.uid)
          .get();
    }
    
    // Trả về document rỗng nếu không có user
    return await FirebaseFirestore.instance
        .collection('khachhang')
        .doc('non_existent_doc')
        .get();
  }
  
  // Hàm tạo ImageProvider dựa trên url
  ImageProvider _getAvatarImage(String url) {
    if (url.startsWith('http') || url.startsWith('https')) {
      return NetworkImage(url);
    } else {
      return AssetImage(url);
    }
  }

  Widget buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color color = Colors.black,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$text chưa được phát triển.")),
              );
            },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.lock, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
