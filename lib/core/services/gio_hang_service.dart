import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GioHangService {
  static final _db = FirebaseFirestore.instance;
  static final _uid = FirebaseAuth.instance.currentUser?.uid ?? "id_test";

  /// Thêm hoặc cập nhật số lượng
  static Future<void> themSanPham(String maSp, int soLuong) async {
    final ref = _db.collection('GioHang').doc(_uid).collection('sanPhams').doc(maSp);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.update({'soLuong': FieldValue.increment(soLuong)});
    } else {
      await ref.set({'maSp': maSp, 'soLuong': soLuong});
    }
  }

  /// Lấy toàn bộ sản phẩm trong giỏ
  static Future<List<Map<String, dynamic>>> layGioHang() async {
    final snapshot = await _db.collection('GioHang').doc(_uid).collection('sanPhams').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Xóa sản phẩm khỏi giỏ
  static Future<void> xoaSanPham(String maSp) async {
    await _db.collection('GioHang').doc(_uid).collection('sanPhams').doc(maSp).delete();
  }
}
