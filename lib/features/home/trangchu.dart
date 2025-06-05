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
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ColorFiltered(
                      colorFilter: sp.soLuongTon == 0
                          ? const ColorFilter.mode(Colors.white70, BlendMode.modulate)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: Image.network(
                        "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  if (sp.soLuongTon == 0)
                    Container(
                      color: Colors.black38,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                        child: Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                sp.tenSanPham,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              sp.soLuongTon == 0
                  ? const SizedBox(height: 20)
                  : Text(
                      NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: '₫',
                      ).format(sp.gia),
                      style: const TextStyle(color: AppColors.primary),
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
        // Thanh tìm kiếm + nút lọc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm sản phẩm...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            search(value.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nút lọc
              InkWell(
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => BoLocSanPham(
                      onFilter: (brand, minGia, maxGia) {
                        filterSanPham(brand, minGia, maxGia);
                      },
                    ),
                  );
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
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

// Widget bộ lọc sản phẩm chuyên nghiệp
class BoLocSanPham extends StatefulWidget {
  final void Function(String brand, double minGia, double maxGia) onFilter;
  const BoLocSanPham({super.key, required this.onFilter});

  @override
  State<BoLocSanPham> createState() => _BoLocSanPhamState();
}

class _BoLocSanPhamState extends State<BoLocSanPham> {
  String selectedBrand = 'Tất cả';
  double minGia = 0;
  double maxGia = 100000000;
  final List<String> brands = [
    'Tất cả', 'Olym Pianus', 'Orient', 'Seiko', 'Casio', 'Citizen', 'Fossil', 'Tissot', 'DW', 'Skagen'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lọc sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Thương hiệu'),
          DropdownButton<String>(
            value: selectedBrand,
            isExpanded: true,
            items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (value) {
              setState(() {
                selectedBrand = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Khoảng giá (VNĐ)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Từ'),
                  onChanged: (val) {
                    minGia = double.tryParse(val) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Đến'),
                  onChanged: (val) {
                    maxGia = double.tryParse(val) ?? 100000000;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFilter(selectedBrand, minGia, maxGia);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Áp dụng', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
