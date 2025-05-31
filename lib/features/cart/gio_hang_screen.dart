import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/gio_hang_service.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';
import 'package:shop_ban_dong_ho/features/orders/thanhtoan.dart';
class GioHangScreen extends StatefulWidget {
  const GioHangScreen({super.key});

  @override
  State<GioHangScreen> createState() => _GioHangScreenState();
}

class _GioHangScreenState extends State<GioHangScreen> {
  List<Map<String, dynamic>> gioHangHienThi = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGioHang();
  }

  Future<void> loadGioHang() async {
    final rawItems = await GioHangService.layGioHang();
    List<Map<String, dynamic>> tempList = [];
    
    for (var item in rawItems) {
      final maSp = item['maSp'];
      final soLuong = item['soLuong'];

      final spSnapshot = await FirebaseFirestore.instance
          .collection('SanPham')
          .where('maSp', isEqualTo: maSp)
          .limit(1)
          .get();

      if (spSnapshot.docs.isNotEmpty) {
        final spData = spSnapshot.docs.first.data();
        final sanPham = SanPham.fromJson(spData);

        tempList.add({'sanPham': sanPham, 'soLuong': soLuong});
      }
    }

   
    if (!mounted) return;

    setState(() {
      gioHangHienThi = tempList;
      isLoading = false;
    });
  }

  double tinhTongTien() {
    return gioHangHienThi.fold(0.0, (total, item) {
      final sp = item['sanPham'] as SanPham;
      final sl = item['soLuong'] as int;
      return total + (sp.gia ?? 0) * sl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : gioHangHienThi.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : ListView.builder(
              itemCount: gioHangHienThi.length,
              itemBuilder: (context, index) {
                final sp = gioHangHienThi[index]['sanPham'] as SanPham;
                final sl = gioHangHienThi[index]['soLuong'] as int;

                return ListTile(
                  leading: Image.network(
                    "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(sp.tenSanPham ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: '₫',
                        ).format(sp.gia),
                      ),
                      Text("Số lượng: $sl"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Xác nhận xoá"),
                          content: const Text(
                            "Bạn có chắc chắn muốn xoá sản phẩm này khỏi giỏ hàng không?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Huỷ"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Xoá",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await xoaSanPham(sp.maSP ?? '');
                        await loadGioHang();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã xoá khỏi giỏ hàng")),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: gioHangHienThi.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tinhTongTien())}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Thanhtoan(),
      ),
    );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text("Thanh toán"),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> xoaSanPham(String maSp) async {
    await GioHangService.xoaSanPham(maSp);
  }
}
