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
  final currentUser = FirebaseAuth.instance.currentUser?.uid ?? "id_test";

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Chờ xác nhận',
      'status': 'pending',
      'icon': Icons.schedule,
      'color': Colors.orange,
    },
    {
      'title': 'Chờ giao hàng',
      'status': 'delivering',
      'icon': Icons.local_shipping,
      'color': Colors.blue,
    },
    {
      'title': 'Đã giao',
      'status': 'completed',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'title': 'Trả hàng',
      'status': 'returned',
      'icon': Icons.assignment_return,
      'color': Colors.purple,
    },
    {
      'title': 'Đã hủy',
      'status': 'cancelled',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  Stream<QuerySnapshot> getDonHangTheoTrangThai(String trangThai) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final query = FirebaseFirestore.instance
        .collection('orders')
        .doc(currentUser)
        .collection('user_orders')
        .where('trangThai', isEqualTo: trangThai);

    if (trangThai == 'completed') {
      return query
          .where(
            'ngayDat',
            isGreaterThanOrEqualTo: Timestamp.fromDate(twoWeeksAgo),
          )
          .snapshots();
    }

    return query.snapshots();
  }

  Future<void> huyDonHang(String orderId, String text) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              if (text == "returned")
                Text("Xác nhận trả hàng")
              else
                Text("Xác nhận hủy đơn"),
            ],
          ),

          content: text == "cancelled"
              ? Text('Bạn có chắc chắn muốn hủy đơn hàng này không?')
              : Text('Bạn có chắc chắn muốn trả đơn hàng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: text == "cancelled"
                  ? const Text('Hủy đơn')
                  : const Text('Trả đơn'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

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
          .update({'trangThai': text});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Đơn hàng đã được hủy thành công'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Lỗi khi hủy đơn: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void moChiTietSanPham(String sanPhamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết sản phẩm'),
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
          ),
          body: Center(child: Text('Chi tiết sản phẩm với ID: $sanPhamId')),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'delivering':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'returned':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'delivering':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'returned':
        return Icons.assignment_return;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'delivering':
        return 'Đang giao hàng';
      case 'completed':
        return 'Đã giao hàng';
      case 'returned':
        return 'Đã trả hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Widget buildDonHangCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusColor = _getStatusColor(data['trangThai']);
    final statusIcon = _getStatusIcon(data['trangThai']);
    final statusText = _getStatusText(data['trangThai']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35),
                  const Color(0xFFFF6B35).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.watch_later_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Đơn hàng #${data['orderId']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Khách hàng: ${data['hoTen']}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sản phẩm",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate((data['danhSachSanPham'] as List).length, (
                  index,
                ) {
                  final sp = data['danhSachSanPham'][index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                sp['hinhAnh'] != null &&
                                    sp['hinhAnh'].toString().isNotEmpty
                                ? Image.network(
                                    "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp['hinhAnh']}.png",
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.watch,
                                              color: Color(0xFFFF6B35),
                                            ),
                                  )
                                : const Icon(
                                    Icons.watch,
                                    color: Color(0xFFFF6B35),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sp['ten'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Số lượng: ${sp['soLuong']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${sp['gia']}đ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(color: Color(0xFFECF0F1)),
                const SizedBox(height: 8),

                // Order Details
                _buildInfoRow("Tổng cộng", "${data['tongCong']}đ", true),
                const SizedBox(height: 8),
                _buildInfoRow("Thanh toán", data['phuongThucThanhToan'], false),
                const SizedBox(height: 8),
                _buildInfoRow("Địa chỉ giao hàng", data['diaChi'], false),

                // Cancel Button
                if (data['trangThai'] == 'pending')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => huyDonHang(data['orderId'], "cancelled"),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Hủy đơn hàng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (data['trangThai'] == 'completed')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => huyDonHang(data['orderId'], "returned"),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Trả hàng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isAmount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 16 : 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFFF6B35),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFF6B35),
              unselectedLabelColor: const Color(0xFF7F8C8D),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              tabs: _tabs.map((tab) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab['icon'], size: 18),
                      const SizedBox(width: 6),
                      Text(tab['title']),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return StreamBuilder<QuerySnapshot>(
            stream: getDonHangTheoTrangThai(tab['status']!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'],
                        size: 80,
                        color: const Color(0xFFBDC3C7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Chưa có đơn hàng nào",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Các đơn hàng ${tab['title'].toLowerCase()} sẽ hiển thị ở đây",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) => buildDonHangCard(docs[index]),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
