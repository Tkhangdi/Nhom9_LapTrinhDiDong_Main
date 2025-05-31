import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/ThongBaoService.dart';
import 'package:shop_ban_dong_ho/features/data/models/ThongBao.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ThongBaoService _thongBaoService = ThongBaoService();
  
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
  
  // Các phương thức xác thực
  Future<User?> dangNhap(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<User?> dangKy(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> dangXuat() async {
    await _auth.signOut();
  }
  
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Phương thức lắng nghe thay đổi trạng thái đơn hàng
  Stream<List<ThongBao>> listenOrderStatusChanges(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ThongBao> notifications = [];
          
          for (var change in snapshot.docChanges) {
            // Chỉ xử lý các thay đổi mới (được thêm hoặc sửa đổi)
            if (change.type == DocumentChangeType.added || 
                change.type == DocumentChangeType.modified) {
              
              var order = change.doc.data();
              if (order != null && order['status'] != null) {
                String title = '';
                String message = '';
                
                // Tạo thông báo dựa trên trạng thái đơn hàng
                switch(order['status']) {
                  case 'pending':
                    title = 'Đơn hàng đang chờ xử lý';
                    message = 'Đơn hàng ${order['orderNumber']} của bạn đang chờ xác nhận.';
                    break;
                  case 'confirmed':
                    title = 'Đơn hàng đã xác nhận';
                    message = 'Đơn hàng ${order['orderNumber']} đã được xác nhận và đang được chuẩn bị.';
                    break;
                  case 'shipping':
                    title = 'Đơn hàng đang vận chuyển';
                    message = 'Đơn hàng ${order['orderNumber']} đang trên đường giao đến bạn.';
                    break;
                  case 'delivered':
                    title = 'Đơn hàng đã giao';
                    message = 'Đơn hàng ${order['orderNumber']} đã được giao thành công. Cảm ơn bạn đã mua hàng!';
                    break;
                  case 'cancelled':
                    title = 'Đơn hàng đã hủy';
                    message = 'Đơn hàng ${order['orderNumber']} đã bị hủy. Liên hệ CSKH để biết thêm chi tiết.';
                    break;
                  default:
                    title = 'Cập nhật đơn hàng';
                    message = 'Đơn hàng ${order['orderNumber']} có cập nhật mới.';
                }
                
                // Tạo thông báo mới
                ThongBao thongBao = ThongBao(
                  title: title,
                  message: message,
                  date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                  type: 1, // Loại thông báo đơn hàng
                );
                
                // Lưu thông báo vào SQLite
                await _thongBaoService.insertThongBao(thongBao);
                
                notifications.add(thongBao);
              }
            }
          }
          
          return notifications;
        });
  }
  
  // Phương thức lắng nghe thông báo khuyến mãi
  Stream<List<ThongBao>> listenPromotions() {
    return _firestore
        .collection('promotions')
        .where('active', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ThongBao> notifications = [];
          
          for (var change in snapshot.docChanges) {
            // Chỉ xử lý các khuyến mãi mới được thêm vào
            if (change.type == DocumentChangeType.added) {
              var promo = change.doc.data();
              if (promo != null) {
                // Tạo thông báo khuyến mãi
                ThongBao thongBao = ThongBao(
                  title: promo['title'] ?? 'Khuyến mãi mới',
                  message: promo['description'] ?? 'Có khuyến mãi mới từ shop. Kiểm tra ngay!',
                  date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                  type: 2, // Loại thông báo khuyến mãi
                );
                
                // Lưu thông báo vào SQLite
                await _thongBaoService.insertThongBao(thongBao);
                
                notifications.add(thongBao);
              }
            }
          }
          
          return notifications;
        });
  }
  
  // Phương thức để xử lý thông báo đẩy từ Cloud Functions
  Future<void> processNotificationFromCloudFunction(Map<String, dynamic> notification) async {
    // Tạo đối tượng thông báo
    ThongBao thongBao = ThongBao(
      title: notification['title'] ?? 'Thông báo mới',
      message: notification['message'] ?? '',
      date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      type: notification['type'] ?? 1, // Mặc định là thông báo đơn hàng
    );
    
    // Lưu thông báo vào SQLite
    await _thongBaoService.insertThongBao(thongBao);
  }

  // Lấy danh sách dữ liệu từ Firestore, sử dụng kiểu dữ liệu generic
  Future<List<T>> fetchData<T>(
    String collectionPath,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();

      // Chuyển các tài liệu thành danh sách đối tượng của kiểu dữ liệu generic
      final dataList =
          querySnapshot.docs.map((doc) {
            return fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

      return dataList;
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  // Thêm dữ liệu vào Firestore (dùng chung cho mọi loại dữ liệu)
  Future<void> addData<T>(
    String collectionPath,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      await _firestore.collection(collectionPath).add(toJson(data));
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  // Cập nhật dữ liệu vào Firestore
  Future<void> updateData<T>(
    String collectionPath,
    String docId,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update(toJson(data));
    } catch (e) {
      print('Error updating data: $e');
    }
  }

  // Xóa dữ liệu khỏi Firestore
  Future<void> deleteData(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print('Error deleting data: $e');
    }
  }
}
