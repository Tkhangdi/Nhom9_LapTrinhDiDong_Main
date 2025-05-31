class GioHangItem {
  final String maSp;
  final int soLuong;

  GioHangItem({
    required this.maSp,
    required this.soLuong,
  });

  Map<String, dynamic> toMap() {
    return {
      'maSp': maSp,
      'soLuong': soLuong,
    };
  }

  factory GioHangItem.fromMap(Map<String, dynamic> map) {
    return GioHangItem(
      maSp: map['maSp'],
      soLuong: map['soLuong'],
    );
  }
}
