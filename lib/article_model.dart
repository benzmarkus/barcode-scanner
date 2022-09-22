class Article {
  int? id;
  String? title;
  double? price;
  String? barcodetype;
  int? barcode;

  Article({this.id, this.title, this.price, this.barcodetype, this.barcode});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'barcode_type': barcodetype,
      'barcode': barcode
    };
  }

  @override
  String toString() {
    return 'Article(id: $id, title:$title, price:$price, barcode_type:$barcodetype, barcode:$barcode';
  }
}

class RouteArguments {
  Article article;
  String method;
  RouteArguments({required this.article, required this.method});
}
