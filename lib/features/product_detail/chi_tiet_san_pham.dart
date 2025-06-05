import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/gio_hang_service.dart';
import 'package:shop_ban_dong_ho/core/services/favorite_db.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';
import 'package:shop_ban_dong_ho/features/data/models/FavoriteItem.dart';
import 'package:shop_ban_dong_ho/features/orders/thanhtoan.dart';

class ChiTietSanPham extends StatefulWidget {
  final SanPham sanPham;
  const ChiTietSanPham({super.key, required this.sanPham});

  @override
  State<ChiTietSanPham> createState() => _ChiTietSanPhamState();
}

class _ChiTietSanPhamState extends State<ChiTietSanPham> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final items = await FavoriteDB.getItems();
    setState(() {
      isFavorite = items.any((item) => item.name == widget.sanPham.tenSanPham);
    });
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) {
      // Xóa khỏi yêu thích
      final items = await FavoriteDB.getItems();
      FavoriteItem? item;
      try {
        item = items.firstWhere((item) => item.name == widget.sanPham.tenSanPham);
      } catch (e) {
        item = null;
      }
      if (item != null && item.id != null) {
        await FavoriteDB.deleteItem(item.id!);
      }
      setState(() {
        isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa khỏi yêu thích!')));
    } else {
      await FavoriteDB.addSanPhamToFavorite(
        name: widget.sanPham.tenSanPham,
        imageUrl: widget.sanPham.hinhAnh.startsWith('http')
            ? widget.sanPham.hinhAnh
            : "https://res.cloudinary.com/dpckj5n6n/image/upload/${widget.sanPham.hinhAnh}.png",
        price: (widget.sanPham.gia ?? 0).toDouble(),
      );
      setState(() {
        isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào yêu thích!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sanPham = widget.sanPham;
    return Scaffold(
      appBar: AppBar(
        title: Text(sanPham.tenSanPham),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            // Icon giỏ hàng
            InkWell(
              onTap: () {
                _showAddToCartSheet(context, sanPham,1);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 28),
              ),
            ),
            const SizedBox(width: 12),

            // Nút mua ngay
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showAddToCartSheet(context, sanPham,2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Mua ngay", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Ảnh sản phẩm
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              sanPham.hinhAnh.startsWith('http')
                  ? sanPham.hinhAnh
                  : "https://res.cloudinary.com/dpckj5n6n/image/upload/${sanPham.hinhAnh}.png",
              fit: BoxFit.cover,
            ),
          ),

          // Thông tin cơ bản
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sanPham.tenSanPham,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(sanPham.gia),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange[400], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${sanPham.soSaoTrungBinh?.toStringAsFixed(1) ?? '0.0'}',
                    ),
                    const SizedBox(width: 10),
                    Text('(Còn ${sanPham.soLuongTon ?? 0} sản phẩm)'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Chi tiết kỹ thuật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Thông tin chi tiết",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _infoRow("Thương hiệu", sanPham.thuongHieu),
                _infoRow("Loại máy", sanPham.loaiMay),
                _infoRow("Kích thước mặt", sanPham.sizeMat),
                _infoRow("Chống nước", sanPham.khangNuoc),
                _infoRow("Đối tượng", sanPham.doiTuong),
                _infoRow("Chất liệu kính", sanPham.chatLieuKinh),
                _infoRow("Chất liệu dây", sanPham.chatLieuDay),
                _infoRow("Độ dày", sanPham.doDay),
                _infoRow("Mã sản phẩm", sanPham.maSP),
                _infoRow("Mô tả chi tiết", sanPham.moTa),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text("$title:")),
          Expanded(
            flex: 6,
            child: Text(
              value ?? "-",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartSheet(BuildContext context, SanPham sp, int k) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ảnh + Giá + Tồn kho
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: '₫',
                              ).format(sp.gia),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Kho: ${sp.soLuongTon}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nhập số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Số lượng", style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            onPressed: quantity < (sp.soLuongTon ?? 1)
                                ? () => setState(() => quantity++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nút thêm vào giỏ
                  if (k == 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          log("đã nhân nút thêm vào giỏ hàng");
                          log('số lượng $quantity sản phẩm ${sp.maSP}');
                          await GioHangService.themSanPham(
                            sp.maSP ?? '',
                            quantity,
                          );
                          log('số lượng $quantity sản phẩm ${sp.maSP}');
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Đã thêm vào giỏ hàng"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Thêm vào Giỏ hàng",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (k == 2)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Thanhtoan(
                                sanPhamMuaNgay: sp.maSP, 
                                soLuongMuaNgay:
                                    quantity, 
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Thanh Toán Ngay",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
