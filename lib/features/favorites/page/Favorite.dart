import 'package:flutter/material.dart';
import 'package:shop_ban_dong_ho/core/services/favorite_db.dart';
import 'package:shop_ban_dong_ho/features/data/models/FavoriteItem.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';
import 'package:shop_ban_dong_ho/features/product_detail/chi_tiet_san_pham.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  List<FavoriteItem> _items = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final data = await FavoriteDB.getItems();
    setState(() {
      _items = data;
    });
  }

  void _showDeleteBottomSheet(BuildContext context, int id) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 150,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Bạn muốn xóa sản phẩm khỏi danh sách yêu thích?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FavoriteDB.deleteItem(id);
                  Navigator.pop(context);
                  loadFavorites();
                },
                child: Text("Xóa"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _items.isEmpty
        ? const Center(child: Text('Chưa có sản phẩm yêu thích', style: TextStyle(fontSize: 16)))
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 36, left: 0, right: 0, bottom: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F00), // Cam đậm
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    SizedBox(width: 18),
                    Icon(Icons.favorite, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Sản phẩm yêu thích',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: _items.length,
                  padding: const EdgeInsets.all(18),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return cardItem(item);
                  },
                ),
              ),
            ],
          );
  }

  Widget cardItem(FavoriteItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Xem chi tiết sản phẩm yêu thích
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChiTietSanPham(sanPham: item.toSanPham()),
            ),
          );
        },
        onLongPress: () => _showDeleteBottomSheet(context, item.id!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Sửa lỗi overflow
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                height: 120, // Giảm chiều cao ảnh
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Giảm padding
              child: Column(
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.price.toStringAsFixed(0)} đ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6), // Giảm padding dưới
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                onPressed: () => _showDeleteBottomSheet(context, item.id!),
                tooltip: 'Xóa khỏi yêu thích',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Thêm hàm chuyển FavoriteItem sang SanPham (giả định có đủ dữ liệu)
extension FavoriteItemToSanPham on FavoriteItem {
  SanPham toSanPham() {
    return SanPham(
      maSP: id?.toString() ?? '',
      tenSanPham: name,
      gia: price.toInt(),
      hinhAnh: imageUrl,
      soLuongTon: 0,
      soSaoTrungBinh: 0,
      moTa: '',
      thuongHieu: '',
      doiTuong: '',
      khangNuoc: '',
      chatLieuKinh: '',
      sizeMat: '',
      doDay: '',
      xuatXu: '',
      loaiMay: '',
      chatLieuDay: '',
      dongsanpham: '',
    );
  }
}
