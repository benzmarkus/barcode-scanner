import 'package:barcode_scanner/article_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;

class DBHelper {
  static Future<void> createArticleTable(sql.Database database) async {
    await database.execute("""
      CREATE TABLE articles (
        title TEXT,
        price REAL,
        barcodetype TEXT,
        barcode INTEGER PRIMARY KEY NOT NULL,
        updatedAt TEXT
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
    final barcode = await db.insert(
      "articles",
      article.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return barcode;
  }

  static Future<int> update(Article article) async {
    final db = await DBHelper.db();
    final result = await db.update(
      "articles",
      article.toMap(),
      where: 'barcode=?',
      whereArgs: [article.barcode],
    );
    return result;
  }

  static Future<int> delete(int barcode) async {
    final db = await DBHelper.db();
    final result = await db.delete(
      "articles",
      where: 'barcode=?',
      whereArgs: [barcode],
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
      orderBy: "title",
    );
    if (articles.isEmpty) {
      return List<Article>.empty();
    }
    final result = List.generate(
      articles.length,
      (index) => Article(
          title: articles[index]["title"],
          price: articles[index]["price"],
          barcodetype: articles[index]["barcodetype"],
          barcode: articles[index]["barcode"],
          updatedAt: DateTime.parse(articles[index]["updatedAt"])),
    );
    return result;
  }

  static Future<List<Article>> findByBarcode(int barcode) async {
    final db = await DBHelper.db();
    final List<Map<String, dynamic>> articles = await db.query(
      "articles",
      orderBy: "title",
      where: "barcode=?",
      whereArgs: [barcode],
      limit: 1,
    );
    final result = List.generate(
      articles.length,
      (index) => Article(
          title: articles[index]["title"],
          price: articles[index]["price"],
          barcodetype: articles[index]["barcodetype"],
          barcode: articles[index]["barcode"],
          updatedAt: DateTime.parse(articles[index]["updatedAt"])),
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
