class FavoriteItem {
  final int? id;
  final String name;
  final String imageUrl;
  final double price;

  FavoriteItem({this.id, required this.name, required this.imageUrl, required this.price});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      price: map['price'],
    );
  }
}
