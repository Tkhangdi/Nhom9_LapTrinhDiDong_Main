class KhachHang {
  String id;
  String hotenkh;
  String email;
  String password;
  String gioitinh;
  String ngaysinh;
  String sdt;
  String diachi;
  String avatarUrl;

  KhachHang({
    required this.id,
    required this.hotenkh,
    required this.email,
    required this.password,
    required this.gioitinh,
    required this.ngaysinh,
    required this.sdt,
    required this.diachi,
    required this.avatarUrl,
  });

  // Convert KhachHang object to a Map (for storing in a database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hotenkh': hotenkh,
      'email': email,
      'password': password,
      'gioitinh': gioitinh,
      'ngaysinh': ngaysinh,
      'sdt': sdt,
      'diachi': diachi,
      'avatarUrl': avatarUrl,
    };
  }

  // Convert Map to a KhachHang object (for retrieving from the database)
  factory KhachHang.fromMap(Map<String, dynamic> map) {
    return KhachHang(
      id: map['id'],
      hotenkh: map['hotenkh'],
      email: map['email'],
      password: map['password'],
      gioitinh: map['gioitinh'],
      ngaysinh: map['ngaysinh'],
      sdt: map['sdt'],
      diachi: map['diachi'],
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }
}
