import 'package:path/path.dart';
import 'package:shop_ban_dong_ho/features/data/models/FavoriteItem.dart';
import 'package:sqflite/sqflite.dart';

class FavoriteDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'favorites.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            imageUrl TEXT,
            price REAL
          )
        ''');

        // Insert 5 fake items
        for (int i = 1; i <= 5; i++) {
          await db.insert('favorites', {
            'name': 'Sản phẩm $i',
            'imageUrl': 'https://shopdunk.com/images/thumbs/0026813_apple-watch-s6-gps-chinh-hang-cu-dep.png',
            'price': (i * 10).toDouble()
          });
        }
      },
    );
  }

  static Future<List<FavoriteItem>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => FavoriteItem.fromMap(maps[i]));
  }

  static Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }
}
