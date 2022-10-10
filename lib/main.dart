import 'package:barcode_scanner/article_form.dart';
import 'package:barcode_scanner/scanned_articles.dart';
import 'package:barcode_scanner/scanner.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    title: 'Barcode Scanner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.orange,
    ),
    initialRoute: "/",
    routes: {
      "/": (context) => const ScannedArticles(),
      "/scanner": (context) => const BarcodeScanner(),
      "/form": (context) => const ArticleForm(),
    },
  ));
}
