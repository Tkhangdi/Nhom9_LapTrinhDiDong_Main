import 'package:flutter/material.dart';
import 'package:shop_ban_dong_ho/core/services/favorite_db.dart';
import 'package:shop_ban_dong_ho/features/data/models/FavoriteItem.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  List<FavoriteItem> _items = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final data = await FavoriteDB.getItems();
    setState(() {
      _items = data;
    });
  }

  void _showDeleteBottomSheet(BuildContext context, int id) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 150,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Bạn muốn xóa sản phẩm khỏi danh sách yêu thích?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FavoriteDB.deleteItem(id);
                  Navigator.pop(context);
                  loadFavorites();
                },
                child: Text("Xóa"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget cardItem(FavoriteItem item) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(149, 157, 165, 0.2),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Image.network(item.imageUrl, fit: BoxFit.cover),
          ),
          SizedBox(height: 8),
          Text(item.name, maxLines: 2),
          SizedBox(height: 4),
          Text(
            "\$${item.price.toStringAsFixed(2)}",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _items.isEmpty
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.7,
            ),
            itemCount: _items.length,
            padding: EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final item = _items[index];
              return GestureDetector(
                onLongPress: () => _showDeleteBottomSheet(context, item.id!),
                child: cardItem(item),
              );
            },
          );
  }
}
