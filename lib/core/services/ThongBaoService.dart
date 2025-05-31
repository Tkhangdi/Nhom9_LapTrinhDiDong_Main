import 'package:path/path.dart';
import 'package:shop_ban_dong_ho/features/data/models/ThongBao.dart';
import 'package:sqflite/sqflite.dart';


class ThongBaoService {
  static final ThongBaoService _instance = ThongBaoService._internal();
  static Database? _database;

  factory ThongBaoService() {
    return _instance;
  }

  ThongBaoService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'thongbao_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE thongbao(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT,
        date TEXT,
        type INTEGER,
        isRead INTEGER
      )
    ''');
  }

  // Thêm thông báo mới
  Future<int> insertThongBao(ThongBao thongBao) async {
    final db = await database;
    return await db.insert('thongbao', thongBao.toMap());
  }

  // Lấy tất cả thông báo
  Future<List<ThongBao>> getAllThongBao() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('thongbao');
    return List.generate(maps.length, (i) {
      return ThongBao.fromMap(maps[i]);
    });
  }

  // Lấy thông báo theo loại
  Future<List<ThongBao>> getThongBaoByType(int type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'thongbao',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) {
      return ThongBao.fromMap(maps[i]);
    });
  }

  // Đánh dấu thông báo đã đọc
  Future<int> markAsRead(int id) async {
    final db = await database;
    return await db.update(
      'thongbao',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa một thông báo
  Future<int> deleteThongBao(int id) async {
    final db = await database;
    return await db.delete(
      'thongbao',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa tất cả thông báo
  Future<int> deleteAllThongBao() async {
    final db = await database;
    return await db.delete('thongbao');
  }
}