import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuanLyDonHangScreen extends StatefulWidget {
  const QuanLyDonHangScreen({super.key});

  @override
  State<QuanLyDonHangScreen> createState() => _QuanLyDonHangScreenState();
}

class _QuanLyDonHangScreenState extends State<QuanLyDonHangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser?.uid??"id_test";

  final List<Map<String, String>> _tabs = [
    {'title': 'Chờ xác nhận', 'status': 'pending'},
    {'title': 'Chờ giao hàng', 'status': 'delivering'},
    {'title': 'Đã giao', 'status': 'delivered'},
    {'title': 'Trả hàng', 'status': 'returned'},
    {'title': 'Đã hủy', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  Stream<QuerySnapshot> getDonHangTheoTrangThai(String trangThai) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(currentUser)
        .collection('user_orders')
        .where('trangThai', isEqualTo: trangThai)
        .snapshots();
  }

  Future<void> huyDonHang(String orderId) async {
    try {
      // Lấy đơn hàng để hoàn trả số lượng sản phẩm
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentUser)
          .collection('user_orders')
          .doc(orderId)
          .get();
      final orderData = orderDoc.data();
      if (orderData != null && orderData['danhSachSanPham'] != null) {
        for (var item in orderData['danhSachSanPham']) {
          final maSp = item['id'];
          final soLuong = item['soLuong'] ?? 0;
          // Lấy sản phẩm hiện tại
          final spSnapshot = await FirebaseFirestore.instance
              .collection('SanPham')
              .where('maSp', isEqualTo: maSp)
              .limit(1)
              .get();
          if (spSnapshot.docs.isNotEmpty) {
            final spDoc = spSnapshot.docs.first;
            final currentTon = spDoc['soLuongTon'] ?? 0;
            await spDoc.reference.update({'soLuongTon': currentTon + soLuong});
          }
        }
      }
      // Cập nhật trạng thái đơn hàng
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentUser)
          .collection('user_orders')
          .doc(orderId)
          .update({'trangThai': 'cancelled'});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đơn hàng đã được hủy.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy đơn: $e')));
    }
  }

  void moChiTietSanPham(String sanPhamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
          body: Center(child: Text('Chi tiết sản phẩm với ID: $sanPhamId')),
        ),
      ),
    );
  }

  Widget buildDonHangCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text("Mã đơn: ${data['orderId']}"),
        subtitle: Text("Khách: ${data['hoTen']}"),
        children: [
          ...List.generate((data['danhSachSanPham'] as List).length, (index) {
            final sp = data['danhSachSanPham'][index];
            return ListTile(
              leading:
                  sp['hinhAnh'] != null && sp['hinhAnh'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp['hinhAnh']}.png",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                    )
                  : const Icon(Icons.image),
              title: Text(sp['ten']),
              subtitle: Text('Số lượng: ${sp['soLuong']}'),
              trailing: Text('${sp['gia']}đ'),
              onTap: () => moChiTietSanPham(sp['id']),
            );
          }),
          const Divider(),
          ListTile(
            title: const Text("Tổng cộng"),
            trailing: Text("${data['tongCong']}đ"),
          ),
          ListTile(
            title: const Text("Phương thức thanh toán"),
            trailing: Text(data['phuongThucThanhToan']),
          ),
          ListTile(
            title: const Text("Địa chỉ giao hàng"),
            subtitle: Text(data['diaChi']),
          ),
          if (data['trangThai'] != 'cancelled' &&
              data['trangThai'] != 'delivered')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => huyDonHang(data['orderId']),
                icon: const Icon(Icons.cancel),
                label: const Text('Hủy đơn hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý đơn hàng'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((tab) => Tab(text: tab['title'])).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
            return StreamBuilder<QuerySnapshot>(
              stream: getDonHangTheoTrangThai(tab['status']!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có đơn hàng."));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) =>
                      buildDonHangCard(docs[index]),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
