import 'package:barcode_scanner/article_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

class DBHelper {
  static Future<void> createArticleTable(sql.Database database) async {
    await database.execute("""
      CREATE TABLE articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        price REAL,
        barcode_type TEXT,
        barcode INTEGER NOT NULL UNIQUE,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP
      )
    """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      join(await sql.getDatabasesPath(), 'items.db'),
      version: 1,
      onCreate: (db, version) async => await createArticleTable(db),
    );
  }

  static Future<int> insert(Article article) async {
    final db = await DBHelper.db();
    final id = await db.insert(
      "articles",
      article.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> update(Article article) async {
    final db = await DBHelper.db();
    final result = await db.update(
      "articles",
      article.toMap(),
      where: 'id=?',
      whereArgs: [article.id],
    );
    return result;
  }

  static Future<int> delete(int id) async {
    final db = await DBHelper.db();
    final result = await db.delete(
      "articles",
      where: 'id=?',
      whereArgs: [id],
    );
    return result;
  }

  static Future<int> deleteAll() async {
    final db = await DBHelper.db();
    final result = await db.delete("articles");
    return result;
  }

  static Future<List<Article>> all() async {
    final db = await DBHelper.db();
    final List<Map<String, dynamic>> articles = await db.query(
      "articles",
      orderBy: "id",
    );
    final result = List.generate(
      articles.length,
      (index) => Article(
          id: articles[index]["id"],
          title: articles[index]["title"],
          price: articles[index]["price"],
          barcodetype: articles[index]["barcodetype"],
          barcode: articles[index]["barcode"]),
    );
    return result;
  }

  static Future<List<Article>> findById(int id) async {
    final db = await DBHelper.db();
    final List<Map<String, dynamic>> articles = await db.query(
      "articles",
      orderBy: "id",
      where: "id=?",
      whereArgs: [id],
      limit: 1,
    );
    final result = List.generate(
      articles.length,
      (index) => Article(
          id: articles[index]["id"],
          title: articles[index]["title"],
          price: articles[index]["price"],
          barcodetype: articles[index]["barcodetype"],
          barcode: articles[index]["barcode"]),
    );
    return result;
  }

  static Future<List<Article>> findByBarcode(int barcode) async {
    final db = await DBHelper.db();
    final List<Map<String, dynamic>> articles = await db.query(
      "articles",
      orderBy: "id",
      where: "barcode=?",
      whereArgs: [barcode],
      limit: 1,
    );
    final result = List.generate(
      articles.length,
      (index) => Article(
          id: articles[index]["id"],
          title: articles[index]["title"],
          price: articles[index]["price"],
          barcodetype: articles[index]["barcodetype"],
          barcode: articles[index]["barcode"]),
    );
    return result;
  }

  static Future<int?> findCountByBarcode(int barcode) async {
    final db = await DBHelper.db();
    final int? counts = sql.Sqflite.firstIntValue(await db.rawQuery(
        "SELECT count(*) FROM articles a WHERE a.barcode = ? ", [barcode]));
    return counts;
  }
}
