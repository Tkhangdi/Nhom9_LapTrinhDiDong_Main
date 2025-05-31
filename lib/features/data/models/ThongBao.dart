class ThongBao {
  int? id;
  String title;
  String message;
  String date;
  int type; // 1: Đơn hàng, 2: Khuyến mãi
  bool isRead;
  
  ThongBao({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });
  
  // Chuyển đổi từ Map để đọc từ database
  factory ThongBao.fromMap(Map<String, dynamic> map) {
    return ThongBao(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      date: map['date'],
      type: map['type'],
      isRead: map['isRead'] == 1,
    );
  }
  
  // Chuyển đổi sang Map để lưu vào database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'type': type,
      'isRead': isRead ? 1 : 0,
    };
  }
}