import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/core/services/ThongBaoService.dart';
import 'package:shop_ban_dong_ho/features/data/models/ThongBao.dart';


class PushNotificationService {
  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();
  
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ThongBaoService _thongBaoService = ThongBaoService();
  
  // Theo dõi các kênh stream
  StreamSubscription? _orderSubscription;
  StreamSubscription? _promotionSubscription;
  
  Future<void> init() async {
    // Cấu hình thông báo local
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    
    // Yêu cầu quyền hiển thị thông báo
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Xử lý thông báo khi app trong foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
    
    // Xử lý thông báo khi nhấp vào thông báo và mở app từ background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A notification was clicked on while the app was in the background!');
      // Chuyển hướng đến màn hình liên quan nếu cần
    });
    
    // Khởi tạo theo dõi sự thay đổi từ Firestore (thay thế cho Cloud Functions)
    _initFirestoreListeners();
  }
  
  void _handleForegroundMessage(RemoteMessage message) async {
    // Hiển thị thông báo local
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'shop_dong_ho_channel',
            'Thông báo Shop Đồng Hồ',
            channelDescription: 'Kênh thông báo cho ứng dụng Shop Đồng Hồ',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
    
    // Lưu thông báo vào SQLite
    if (message.data.isNotEmpty) {
      await _saveNotificationToSQLite(
        title: notification?.title ?? message.data['title'] ?? 'Thông báo mới',
        body: notification?.body ?? message.data['message'] ?? '',
        type: int.tryParse(message.data['type'] ?? '1') ?? 1,
      );
    }
  }
  
  Future<void> _saveNotificationToSQLite({
    required String title,
    required String body,
    required int type,
  }) async {
    await _thongBaoService.insertThongBao(
      ThongBao(
        title: title,
        message: body,
        date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        type: type,
      ),
    );
  }
  
  void _initFirestoreListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Hủy đăng ký nếu đã đăng ký trước đó
    _disposeListeners();
    
    // Theo dõi thay đổi trạng thái đơn hàng
    _orderSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(_handleOrderChanges);
    
    // Theo dõi khuyến mãi mới
    _promotionSubscription = _firestore
        .collection('promotions')
        .where('active', isEqualTo: true)
        .snapshots()
        .listen(_handlePromotionChanges);
  }
  
  void _handleOrderChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      // Chỉ xử lý các thay đổi khi thêm mới hoặc cập nhật
      if (change.type == DocumentChangeType.added || 
          change.type == DocumentChangeType.modified) {
        
        var order = change.doc.data() as Map<String, dynamic>?;
        if (order != null && order['status'] != null) {
          String title = '';
          String message = '';
          String orderNumber = order['orderNumber'] ?? 'N/A';
          
          // Tạo thông báo dựa trên trạng thái đơn hàng
          switch(order['status']) {
            case 'pending':
              title = 'Đơn hàng đang chờ xử lý';
              message = 'Đơn hàng $orderNumber của bạn đang chờ xác nhận.';
              break;
            case 'confirmed':
              title = 'Đơn hàng đã xác nhận';
              message = 'Đơn hàng $orderNumber đã được xác nhận và đang được chuẩn bị.';
              break;
            case 'shipping':
              title = 'Đơn hàng đang vận chuyển';
              message = 'Đơn hàng $orderNumber đang trên đường giao đến bạn.';
              break;
            case 'delivered':
              title = 'Đơn hàng đã giao';
              message = 'Đơn hàng $orderNumber đã được giao thành công. Cảm ơn bạn đã mua hàng!';
              break;
            case 'cancelled':
              title = 'Đơn hàng đã hủy';
              message = 'Đơn hàng $orderNumber đã bị hủy. Liên hệ CSKH để biết thêm chi tiết.';
              break;
            default:
              title = 'Cập nhật đơn hàng';
              message = 'Đơn hàng $orderNumber có cập nhật mới.';
          }
          
          // Lưu thông báo vào SQLite
          await _saveNotificationToSQLite(
            title: title,
            body: message,
            type: 1, // Đơn hàng
          );
          
          // Hiển thị thông báo local
          await _showLocalNotification(title, message);
        }
      }
    }
  }
  
  void _handlePromotionChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      // Chỉ xử lý các khuyến mãi mới
      if (change.type == DocumentChangeType.added) {
        var promo = change.doc.data() as Map<String, dynamic>?;
        if (promo != null) {
          String title = promo['title'] ?? 'Khuyến mãi mới';
          String message = promo['description'] ?? 'Có khuyến mãi mới từ shop. Kiểm tra ngay!';
          
          // Lưu thông báo vào SQLite
          await _saveNotificationToSQLite(
            title: title,
            body: message,
            type: 2, // Khuyến mãi
          );
          
          // Hiển thị thông báo local
          await _showLocalNotification(title, message);
        }
      }
    }
  }
  
  Future<void> _showLocalNotification(String title, String body) async {
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'shop_dong_ho_channel',
          'Thông báo Shop Đồng Hồ',
          channelDescription: 'Kênh thông báo cho ứng dụng Shop Đồng Hồ',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
  
  void _disposeListeners() {
    _orderSubscription?.cancel();
    _promotionSubscription?.cancel();
  }
  
  void dispose() {
    _disposeListeners();
  }
  
  // Gọi phương thức này khi đăng nhập/đăng xuất để cập nhật listeners
  void updateUser() {
    _initFirestoreListeners();
  }
}