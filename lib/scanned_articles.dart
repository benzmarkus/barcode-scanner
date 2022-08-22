import 'package:barcode_scanner/article_model.dart';
import 'package:barcode_scanner/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ScannedArticles extends StatefulWidget {
  const ScannedArticles({Key? key}) : super(key: key);
  @override
  State<ScannedArticles> createState() => _ScannedArticles();
}

class _ScannedArticles extends State<ScannedArticles> {
  List<Article> _articles = <Article>[];
  String _scanBarcode = 'Unknown';
  bool isLoading = true;

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      // print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });

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
      Navigator.pushNamed(context, "/form", arguments: _arguments);
    }
  }

  void _syncWithCloud() async {
    int result = await DBHelper.deleteAll();
    List<Article> demo_articles = <Article>[
      Article(
          barcode: 978020137962,
          barcodetype: "EN_13",
          title: "Item 1",
          price: 5.44),
      Article(
          barcode: 978020137963,
          barcodetype: "EN_13",
          title: "Item 2",
          price: 4.4),
      Article(
          barcode: 978020137964,
          barcodetype: "EN_13",
          title: "Item 3",
          price: 4)
    ];

    demo_articles.forEach((article) async {
      var int = await DBHelper.insert(article);
    });
    _loadArticles();
  }

  void _loadArticles() async {
    var articles = await DBHelper.all();
    setState(() {
      _articles = articles;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    _loadArticles();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Articles"),
        actions: [
          IconButton(
            onPressed: _syncWithCloud,
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
                Expanded(
                  child: ListView.builder(
                    itemCount: _articles.length,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          tileColor: Colors.amber[300],
                          title: Text(
                            _articles[index].title.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _articles[index].price.toString(),
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
                                      article: _articles[index],
                                      method: "EDIT"),
                                ),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeleteAlert(
                                      context, _articles[index].id!);
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

  _showDeleteAlert(BuildContext context, int id) {
    Widget okButton = TextButton(
      onPressed: () async {
        Navigator.of(context).pop();
        final result = await DBHelper.delete(id);
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
                  barcode: int.parse(_scanBarcode), price: 0, title: ""),
              method: "ADD"),
        );
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
}
