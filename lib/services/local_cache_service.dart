import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 🆕 LocalCacheService
/// طبقة تخزين محلية عامة (key → JSON نصي) فوق sqflite، تُستخدم من
/// ApiService لحفظ آخر رد ناجح من أي GET endpoint، والرجوع لهاي النسخة
/// المحفوظة تلقائياً لما ما يكون في اتصال بالإنترنت أو يفشل الطلب.
///
/// ليش key-value عام بدل جدول مخصص لكل نوع بيانات (واجبات، غياب...)؟
/// لأنه أبسط وأأمن بكتير: منخزن نفس الـ JSON يلي السيرفر بيرجعه بالضبط
/// بدون ما نعيد تعريف/نطابق بنية كل جدول بقاعدة بياناتك يدوياً — وأي
/// endpoint جديد تضيفه لاحقاً بتقدر تربطه بالكاش بسطر واحد بس
/// (استخدام _getJsonCached بـ ApiService)، بدون تعديل هالملف نهائياً.
class LocalCacheService {
  static const String _dbName = 'app_offline_cache.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache_store (
            cache_key   TEXT PRIMARY KEY,
            json_data   TEXT NOT NULL,
            updated_at  INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// يقرأ آخر نسخة محفوظة لهالمفتاح، أو null لو ما كانت موجودة أصلاً.
  Future<String?> read(String key) async {
    try {
      final db = await _database;
      final rows = await db.query(
        'cache_store',
        columns: ['json_data'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['json_data'] as String?;
    } catch (_) {
      return null; // أي مشكلة بالقراءة المحلية ما لازم توقف باقي التطبيق
    }
  }

  /// يخزن/يحدّث نسخة الـ JSON لهالمفتاح مع وقت الحفظ الحالي.
  Future<void> write(String key, String jsonData) async {
    try {
      final db = await _database;
      await db.insert(
        'cache_store',
        {
          'cache_key': key,
          'json_data': jsonData,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // فشل الكتابة بالكاش ما لازم يوقف عرض البيانات الطازة اللي وصلت تو
    }
  }

  /// وقت آخر تحديث لهالمفتاح (millisecondsSinceEpoch)، أو null لو غير محفوظ.
  Future<int?> lastUpdated(String key) async {
    try {
      final db = await _database;
      final rows = await db.query(
        'cache_store',
        columns: ['updated_at'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['updated_at'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// يمسح مفتاح واحد (نادراً ما تحتاجه — مثلاً بعد تسجيل خروج لحساب
  /// معيّن إذا بدك تمسح بياناته المحفوظة تحديداً).
  Future<void> delete(String key) async {
    try {
      final db = await _database;
      await db.delete('cache_store', where: 'cache_key = ?', whereArgs: [key]);
    } catch (_) {}
  }

  /// يمسح كل الكاش بالكامل — استخدمها عند تسجيل الخروج (logout) حتى ما
  /// يضل حساب سابق شايف بيانات محفوظة لحساب غيره لو تسجل حدا تاني عنفس
  /// الجهاز.
  Future<void> clearAll() async {
    try {
      final db = await _database;
      await db.delete('cache_store');
    } catch (_) {}
  }
}
