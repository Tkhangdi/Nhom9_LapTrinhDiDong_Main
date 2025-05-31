import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/FirebaseService.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';

import 'package:flutter/material.dart';
import 'package:shop_ban_dong_ho/features/home/widgets/danh_sach_san_pham.dart';

final GlobalKey<_HomePageState> trangChuKey = GlobalKey<_HomePageState>();

class TrangChu extends StatefulWidget {
  const TrangChu({super.key});

  @override
  State<TrangChu> createState() => _HomePageState();
}

class _HomePageState extends State<TrangChu> {
  String searchKeyword = ''; //biến tìm kiếm

  final firebaseService = FirebaseService();

  List<SanPham> list1 = [];
  List<SanPham> list2 = [];
  Future<List<SanPham>> fetchSanPhamList() {
    return firebaseService.fetchData(
      "SanPham",
      (json) => SanPham.fromJson(json),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  //load có tích hợp tìm kiếm
  Future<void> loadData() async {
    final data = await fetchSanPhamList();

    final filtered = data.where((sp) {
      return sp.tenSanPham.toLowerCase().contains(searchKeyword.toLowerCase());
    }).toList();
    
    final half = (filtered.length / 2).ceil();
      if (!mounted) return;
    setState(() {
      list1 = filtered.sublist(0, half);
      list2 = filtered.sublist(half);
    });
  }

  void search(String keyword) {
    searchKeyword = keyword;
    loadData();
  }

  Widget cardItem(SanPham sp) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 85, 84, 84)
            : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          hoverColor: Colors.transparent,
          onTap: () {},
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(
                  6,
                ), // hoặc EdgeInsets.symmetric(...) nếu muốn chỉ theo chiều ngang/dọc
                child: Image.network(
                  "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                  fit: BoxFit.fill,
                ),
              ),
              Text(
                sp.tenSanPham,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              Text(
                NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: '₫',
                ).format(sp.gia),
                style: TextStyle(color: AppColors.primary),

                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Image.network(
              "https://cdnv2.tgdd.vn/mwg-static/topzone/Banner/85/56/8556772b83e9bd7198500df457f00498.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
        const Text(
          "Sản Phẩm Mới Nhất 2025",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(
          color: AppColors.primary,
          thickness: 2,
          indent: 20,
          endIndent: 20,
        ),
        DanhSachSanPham(list1: list1, list2: list2),
      ],
    );
  }

  //hàm lọc sản phẩm
  void filterSanPham(String brand, double minGia, double maxGia) async {
    final data = await fetchSanPhamList();

    final filtered = data.where((sp) {
      final byName = sp.tenSanPham.toLowerCase().contains(
        searchKeyword.toLowerCase(),
      );
      final byBrand =
          brand == 'Tất cả' ||
          brand.isEmpty ||
          (sp.thuongHieu ?? '').toLowerCase() == brand.toLowerCase();
      final byGia = (sp.gia ?? 0) >= minGia && (sp.gia ?? 0) <= maxGia;
      return byName && byBrand && byGia;
    }).toList();

    final half = (filtered.length / 2).ceil();
    if (!mounted) return;
    setState(() {
      list1 = filtered.sublist(0, half);
      list2 = filtered.sublist(half);
    });
  }
}
