import 'package:barcode_scanner/article_model.dart';
import 'package:barcode_scanner/db_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkdigit/checkdigit.dart';

class ScannedArticles extends StatefulWidget {
  const ScannedArticles({Key? key}) : super(key: key);
  @override
  State<ScannedArticles> createState() => _ScannedArticles();
}

class _ScannedArticles extends State<ScannedArticles> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<Article> _articles = <Article>[];
  List<Article> _foundArticles = <Article>[];

  String _scanBarcode = 'Unknown';
  String _barcodetype = '';
  bool isLoading = true;
  TextEditingController _unameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
    if (!ean8.validate(_scanBarcode) && !ean13.validate(_scanBarcode)) {
      print("EAN8/EAN13 not valid");
      return;
    }

    if (ean8.validate(_scanBarcode)) {
      _barcodetype = "EAN8";
    }
    if (ean13.validate(_scanBarcode)) {
      _barcodetype = "EAN13";
    }
    
    // check if barcode already exists
    final int? exits =
        await DBHelper.findCountByBarcode(int.parse(_scanBarcode));
    // barcode does not exists register
    if (exits == 0 || exits == null) {
      _showNewBarcodeAlert();
    } else {
      // if barcode exists then find and show form
      final List<Article> article =
          await DBHelper.findByBarcode(int.parse(_scanBarcode));
      final _arguments = RouteArguments(article: article.first, method: "EDIT");
      Navigator.pushNamed(context, "/form", arguments: _arguments)
          .whenComplete(() => setState(() => {_loadArticles()}));
    }
  }

  void _syncWithCloud(
      List<Article> article, String username, String password) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString("username", username);
    await prefs.setString("password", password);
    var result = <Article>[];
    if (article.isNotEmpty) {
      article.forEach((element) => result.add(Article(
          title: element.title,
          price: element.price,
          barcode: element.barcode,
          barcodetype: element.barcodetype,
          updatedAt: element.updatedAt)));
    }

    try {
      final db = FirebaseFirestore.instance;
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: username.trim().toLowerCase(), password: password.trim());

      final articlesToCreate = <Article>[];
      final articlesToUpdate = <Article>[];
      final collection =
          db.collection("users/${credential.user?.uid}/documents");

      final event = await collection.get();
      final articlesFromTheCloud = event.docs.isEmpty
          ? List<Article>.empty()
          : List<Article>.generate(
              event.docs.length,
              (index) => Article(
                  title: event.docs[index]["title"],
                  price: event.docs[index]["price"],
                  barcodetype: event.docs[index]["barcodetype"],
                  barcode: event.docs[index]["barcode"],
                  updatedAt: DateTime.parse(event.docs[index]["updatedAt"])),
            );
      result.forEach((element) {
        var foundInCloud = articlesFromTheCloud.isEmpty
            ? <Article>[]
            : articlesFromTheCloud.where((c) => c.barcode == element.barcode);
        if (foundInCloud.isNotEmpty && element != null) {
          if (foundInCloud.first.updatedAt != null &&
              element.updatedAt != null) {
            if (element.updatedAt?.isBefore(foundInCloud.first.updatedAt!) ??
                false) {
              element.updatedAt = foundInCloud.first.updatedAt;
              element.price = foundInCloud.first.price;
              element.title = foundInCloud.first.title;
            } else {
              articlesToUpdate.add(Article(
                title: element.title,
                price: element.price,
                barcode: element.barcode,
                barcodetype: element.barcodetype,
                updatedAt: element.updatedAt));
            }
          } else {
            if (element.updatedAt != null) {
              element.updatedAt = foundInCloud.first.updatedAt;
              element.price = foundInCloud.first.price;
              element.title = foundInCloud.first.title;
            }
          }
        } else {
          articlesToCreate.add(element);
        }
      });
      final batch = db.batch();
      articlesToCreate.forEach((element) {
        var nycRef = collection.doc();
        final docToStore = element.toMap();
        batch.set(nycRef, docToStore);
      });
      articlesToUpdate.forEach((element) {
        final found =
            event.docs.where((i) => i["barcode"] == element.barcode).toList();
        if (found.isNotEmpty) {
          var nycRef = collection.doc(found.first.id);
          final docToStore = element.toMap();
          batch.update(nycRef, docToStore);
        }
      });
      await batch.commit();

      if (articlesFromTheCloud.isNotEmpty) {
        articlesFromTheCloud.forEach((element) {
          final found = article.where((i) => i.barcode == element.barcode);
          if (found.isEmpty) {
            result.add(Article(
                title: element.title,
                price: element.price,
                barcode: element.barcode,
                barcodetype: element.barcodetype,
                updatedAt: element.updatedAt));
          }
        });
      }
    } catch (e) {
      print(e);
    } finally {
      FirebaseAuth.instance.signOut();
    }
    await DBHelper.deleteAll();

    result.forEach((a) async {
      await DBHelper.insert(a);
    });
    _loadArticles();
  }

  void _loadArticles() async {
    var articles = await DBHelper.all();
    setState(() {
      _foundArticles = articles;
      _articles = articles;
      isLoading = false;
    });
  }

  onSearch(String v) {
    setState(() {
      var searchString = v.toLowerCase();
      _foundArticles = _articles
          .where((article) => article.title!.toLowerCase().contains(searchString))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Articles"),
        actions: [
          IconButton(
            onPressed: _showLoginDialog,
            icon: Icon(Icons.sync),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.amber,
              ),
            )
          : Column(
              children: [
                TextField(
                  onChanged: (v) => {onSearch(v)},
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search Articles",
                      hintStyle: TextStyle(
                        fontSize: 14,
                      )),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _foundArticles.length,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          tileColor: Colors.amber[300],
                          title: Text(
                            _foundArticles[index].title.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _foundArticles[index].price.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  "/form",
                                  arguments: RouteArguments(
                                      article: _foundArticles[index],
                                      method: "EDIT"),
                                ),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeleteAlert(
                                      context, _foundArticles[index].barcode!);
                                },
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => scanBarcodeNormal(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }

  _showDeleteAlert(BuildContext context, int barcode) {
    Widget okButton = TextButton(
      onPressed: () async {
        Navigator.of(context).pop();
        final result = await DBHelper.delete(barcode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('article deleted'),
          ),
        );
        _loadArticles();
      },
      child: const Text("OK"),
    );

    Widget cancelButton = TextButton(
      onPressed: () => {Navigator.of(context).pop()},
      child: const Text("No"),
    );

    AlertDialog deleteAlert = AlertDialog(
      title: const Text("Delete Article"),
      content: const Text("Are you sure ?"),
      actions: [okButton, cancelButton],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return deleteAlert;
        });
  }

  _showNewBarcodeAlert() {
    Widget registerButton = TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.pushNamed(
          context,
          "/form",
          arguments: RouteArguments(
              article: Article(
                  barcode: int.parse(_scanBarcode), price: 0, title: "", barcodetype: _barcodetype),
              method: "ADD"),
        ).whenComplete(() => {
              setState(
                () {
                  _loadArticles();
                },
              )
            });
      },
      child: const Text("Register"),
    );
    Widget cancelButton = TextButton(
      onPressed: () => {Navigator.of(context).pop()},
      child: const Text("Cancel"),
    );
    AlertDialog registerAlert = AlertDialog(
      title: const Text("New Article"),
      content: const Text("Do you want to register?"),
      actions: [registerButton, cancelButton],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return registerAlert;
        });
  }

  _showLoginDialog() async {
    final SharedPreferences prefs = await _prefs;
    Widget syncButton = TextButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          Navigator.of(context).pop();
          _syncWithCloud(
              _articles, _unameController.text, _passwordController.text);
        }
      },
      child: const Text("Sync"),
    );
    Widget cancelButton = TextButton(
      onPressed: () => {Navigator.of(context).pop()},
      child: const Text("Cancel"),
    );
    AlertDialog loginAlert = AlertDialog(
      title: const Text("Sync"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.perm_identity),
                  // hintText: 'Enter Article Title',
                  labelText: 'Username',
                ),
                enabled: true,
                controller: _unameController,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.key),
                  // hintText: 'Enter Article Title',
                  labelText: 'Password',
                ),
                enabled: true,
                obscureText: true,
                controller: _passwordController,
              ),
            ],
          ),
        ),
      ),
      actions: [syncButton, cancelButton],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          _unameController.text = prefs.getString("username") ?? "";
          _passwordController.text = prefs.getString("password") ?? "";
          return loginAlert;
        });
  }
}
