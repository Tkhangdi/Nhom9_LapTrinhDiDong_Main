import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:shop_ban_dong_ho/features/data/models/SanPham.dart';
import 'package:shop_ban_dong_ho/features/product_detail/chi_tiet_san_pham.dart';

class DanhSachSanPham extends StatelessWidget {
  final List<SanPham> list1;
  final List<SanPham> list2;

  const DanhSachSanPham({super.key, required this.list1, required this.list2});

  Widget cardItem(BuildContext context, SanPham sp) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Material(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(255, 85, 84, 84)
                : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChiTietSanPham(sanPham: sp)),
            );
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Image.network(
                  "https://res.cloudinary.com/dpckj5n6n/image/upload/${sp.hinhAnh}.png",
                  fit: BoxFit.fill,
                ),
              ),
              Text(
                sp.tenSanPham ?? "",
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              Text(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: list1.map((sp) => cardItem(context, sp)).toList(),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 20),
              ...list2.map((sp) => cardItem(context, sp)),
            ],
          ),
        ),
      ],
    );
  }
}
