import 'package:barcode_scanner/article_model.dart';
import 'package:barcode_scanner/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArticleForm extends StatefulWidget {
  const ArticleForm({super.key});

  @override
  State<ArticleForm> createState() => _ArticleForm();
}

class _ArticleForm extends State<ArticleForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController priceController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController barcodeContoller = TextEditingController();
  String _method = "ADD";

  @override
  void dispose() {
    priceController.dispose();
    titleController.dispose();
    barcodeContoller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as RouteArguments;

    barcodeContoller.text = args.article.barcode.toString();
    priceController.text = args.article.price.toString();
    titleController.text = args.article.title.toString();
    final String btnText = args.method == "EDIT" ? 'Update' : 'Register';
    final String appTitle =
        args.method == "EDIT" ? 'Update Article' : 'Register Article';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(appTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.bar_chart_outlined),
                  // hintText: 'Enter Article Title',
                  labelText: 'Barcode',
                ),
                enabled: false,
                controller: barcodeContoller,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.type_specimen),
                  // hintText: 'Enter Article Title',
                  labelText: 'Barcode Type',
                ),
                enabled: false,
                initialValue: "EN_13",
              ),
              TextFormField(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.ad_units),
                    // hintText: 'Enter Article Title',
                    labelText: 'Title *',
                  ),
                  controller: titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter title";
                    }
                    return null;
                  }),
              TextFormField(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.euro),
                    // hintText: 'Enter Article Title',
                    labelText: 'Price *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  controller: priceController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter price";
                    }
                    return null;
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (args.method == "ADD") {
                          final Article article = Article(
                              barcode: int.parse(barcodeContoller.text),
                              title: titleController.text,
                              price: double.parse(priceController.text),
                              barcodetype: "EN_13", updatedAt: DateTime.now());
                          await DBHelper.insert(article);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Articles Registerd'),
                            ),
                          );
                        } else {
                          final Article article = Article(
                              barcode: int.parse(barcodeContoller.text),
                              title: titleController.text,
                              price: double.parse(priceController.text),
                              barcodetype: "EN_13", updatedAt: DateTime.now());

                          await DBHelper.update(article);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Articles Updated'),
                            ),
                          );
                        }

                        Navigator.pop(context, true);
                      }
                    },
                    child: Text(btnText),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
