import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/gio_hang_service.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';
import 'package:shop_ban_dong_ho/features/orders/QRCodeScreen.dart';
import 'package:shop_ban_dong_ho/features/orders/quanlydonhang.dart';
import 'package:shop_ban_dong_ho/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: Thanhtoan()));
}

class Thanhtoan extends StatefulWidget {
  final String? sanPhamMuaNgay;
  final int? soLuongMuaNgay;

  const Thanhtoan({super.key, this.sanPhamMuaNgay, this.soLuongMuaNgay});

  @override
  State<Thanhtoan> createState() => _ThanhtoanState();
}

class _ThanhtoanState extends State<Thanhtoan> {
  int _ptThanhToan = 1;
  bool isLoading = true;
  List<Map<String, dynamic>> gioHangHienThi = [];
  Map<String, dynamic>? thongTinNguoiDung;

  void _capNhatPhuongThuc(int value) {
    setState(() {
      _ptThanhToan = value;
    });
  }

  @override
  void initState() {
    super.initState();
    loadThongTinNguoiDung();
    if (widget.sanPhamMuaNgay != null && widget.soLuongMuaNgay != null) {
      loadSanPham();
    } else {
      loadGioHang();
    }
  }

  Future<void> loadThongTinNguoiDung() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;

    final doc = await FirebaseFirestore.instance
        .collection('khachhang')
        .doc(userId)
        .get();

    if (doc.exists) {
      setState(() {
        thongTinNguoiDung = doc.data();
      });
    }
  }

  void loadSanPham() async {
    final spSnapshot = await FirebaseFirestore.instance
        .collection('SanPham')
        .where('maSp', isEqualTo: widget.sanPhamMuaNgay)
        .limit(1)
        .get();
    List<Map<String, dynamic>> tempList = [];
    if (spSnapshot.docs.isNotEmpty) {
      final spData = spSnapshot.docs.first.data();
      final sanPham = SanPham.fromJson(spData);
      tempList.add({'sanPham': sanPham, 'soLuong': widget.soLuongMuaNgay});
    }

    if (!mounted) return;

    setState(() {
      gioHangHienThi = tempList;
      isLoading = false;
    });
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

  Widget thongTinNguoiNhan() {
    if (thongTinNguoiDung == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hoTen = thongTinNguoiDung!['hotenkh'] ?? '';
    final sdt = thongTinNguoiDung!['sdt'] ?? '';
    final diaChi = thongTinNguoiDung!['diachi'] ?? '';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.fmd_good_outlined, size: 20, color: Colors.red),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(hoTen),
                    SizedBox(width: 4),
                    Text(
                      "($sdt)",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Text(diaChi, style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget danhSachSanPham() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: gioHangHienThi.map((item) {
          final SanPham sp = item['sanPham'];
          final int sl = item['soLuong'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Image.network(
                  "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sp.tenSanPham,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                            ).format(sp.gia ?? 0),
                            style: TextStyle(fontSize: 14),
                          ),
                          Text("x$sl", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double tinhTongTien() {
    return gioHangHienThi.fold(0.0, (total, item) {
      final sp = item['sanPham'] as SanPham;
      final sl = item['soLuong'] as int;
      return total + (sp.gia ?? 0) * sl;
    });
  }

  Widget chiTietThanhToan() {
    double phiShip = 20000;
    double tongCong = tinhTongTien() + phiShip;

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chi tiết thanh toán",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 10),
          rowChiTiet(
            "Tổng tiền sản phẩm",
            "${tinhTongTien().toStringAsFixed(0)} đ",
          ),
          rowChiTiet("Phí vận chuyển", "20000 đ"),
          Divider(),
          rowChiTiet(
            "Tổng cộng",
            "${tongCong.toStringAsFixed(0)} đ",
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget rowChiTiet(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  void _datHang() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? "id_test";
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    double phiShip = 20000;
    double tongCong = tinhTongTien() + phiShip;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(userId)
          .collection('user_orders')
          .doc(orderId)
          .set({
            'orderId': orderId,
            'userId': userId,
            'hoTen': thongTinNguoiDung?['hotenkh'] ?? '',
            'soDienThoai': thongTinNguoiDung?['sdt'] ?? '',
            'diaChi': thongTinNguoiDung?['diachi'] ?? '',
            'danhSachSanPham': gioHangHienThi.map((item) {
              final sp = item['sanPham'];
              return {
                'id': sp.maSP,
                'ten': sp.tenSanPham,
                'gia': sp.gia,
                'soLuong': item['soLuong'],
                'hinhAnh': sp.hinhAnh,
              };
            }).toList(),
            'tongTien': tinhTongTien(),
            'phiVanChuyen': phiShip,
            'tongCong': tongCong,
            'phuongThucThanhToan': _ptThanhToan == 1 ? "COD" : "Online",
            'trangThai': _ptThanhToan == 1 ? "pending" : "awaiting_payment",
            'ngayDat': Timestamp.now(),
          });

      for (var item in gioHangHienThi) {
        final sp = item['sanPham'] as SanPham;
        final newSoLuongTon = (sp.soLuongTon ?? 0) - item['soLuong'];
        final snapshot = await FirebaseFirestore.instance
            .collection('SanPham')
            .where('maSp', isEqualTo: sp.maSP)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.update({
            'soLuongTon': newSoLuongTon,
          });
        }
      }

      if (_ptThanhToan == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QRCodeScreen(orderId: orderId, tongCong: tongCong),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuanLyDonHangScreen()),
        );
      }
    } catch (e) {
      print("Lỗi đặt hàng: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi đặt hàng: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thanh toán")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(8),
              children: [
                thongTinNguoiNhan(),
                danhSachSanPham(),
                PtThanhToan(onChanged: _capNhatPhuongThuc),
                chiTietThanhToan(),
              ],
            ),
      backgroundColor: Color(0xFFF5F5F5),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          color: Colors.white,
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _datHang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Đặt hàng", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PtThanhToan extends StatefulWidget {
  final Function(int) onChanged;

  const PtThanhToan({super.key, required this.onChanged});

  @override
  State<PtThanhToan> createState() => _PtThanhToanState();
}

class _PtThanhToanState extends State<PtThanhToan> {
  int _chonpttt = 1;

  void _chon(int value) {
    setState(() {
      _chonpttt = value;
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Phương thức thanh toán",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Column(
            children: [
              ListTile(
                title: Text("Thanh toán tại nhà"),
                leading: Icon(Icons.payments_outlined, color: Colors.green),
                trailing: Radio(
                  value: 1,
                  groupValue: _chonpttt,
                  onChanged: (val) => _chon(val!),
                ),
              ),
              ListTile(
                title: Text("Thanh toán online"),
                leading: Icon(Icons.payment, color: Colors.blueAccent),
                trailing: Radio(
                  value: 2,
                  groupValue: _chonpttt,
                  onChanged: (val) => _chon(val!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
