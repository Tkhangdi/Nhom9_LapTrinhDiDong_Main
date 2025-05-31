class SanPham {
  final String? maSP;
  final String tenSanPham;
  final int? gia;
  final String? moTa;
  final String? thuongHieu;
  final String? doiTuong;
  final String? khangNuoc;
  final String? chatLieuKinh;
  final String? sizeMat;
  final String? doDay;
  final String? xuatXu;
  final String? loaiMay;
  final String? chatLieuDay;
  final String? dongsanpham;
  final String hinhAnh;
  final int? soLuongTon;
  final double? soSaoTrungBinh;

  SanPham({
    required this.maSP,
    required this.tenSanPham,
    required this.gia,
    this.moTa,
    this.thuongHieu,
    this.doiTuong,
    this.khangNuoc,
    this.chatLieuKinh,
    this.sizeMat,
    this.doDay,
    this.xuatXu,
    this.loaiMay,
    this.chatLieuDay,
    this.dongsanpham,
    required this.hinhAnh,
    required this.soLuongTon,
    required this.soSaoTrungBinh,
  });

  factory SanPham.fromJson(Map<String, dynamic> json) => SanPham(
    maSP: json['maSp'],
    tenSanPham: json['tenSanPham'],
    gia: json['gia'],
    moTa: json['moTa'],
    thuongHieu: json['thuongHieu'],
    doiTuong: json['doiTuong'],
    khangNuoc: json['khangNuoc'],
    chatLieuKinh: json['chatLieuKinh'],
    sizeMat: json['sizeMat'],
    doDay: json['doDay'],
    xuatXu: json['xuatXu'],
    loaiMay: json['loaiMay'],
    chatLieuDay: json['chatLieuDay'],
    dongsanpham: json['dongsanpham'],
    hinhAnh: json['hinhAnh'],
    soLuongTon: json['soLuongTon'],
    soSaoTrungBinh: json['soSaoTrungBinh'].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'maSp': maSP,
    'tenSanPham': tenSanPham,
    'gia': gia,
    'moTa': moTa,
    'thuongHieu': thuongHieu,
    'doiTuong': doiTuong,
    'khangNuoc': khangNuoc,
    'chatLieuKinh': chatLieuKinh,
    'sizeMat': sizeMat,
    'doDay': doDay,
    'xuatXu': xuatXu,
    'loaiMay': loaiMay,
    'chatLieuDay': chatLieuDay,
    'dongsanpham': dongsanpham,
    'hinhAnh': hinhAnh,
    'soLuongTon': soLuongTon,
    'soSaoTrungBinh': soSaoTrungBinh,
  };

}
