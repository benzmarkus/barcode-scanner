class Article {
  String? title;
  double? price;
  String? barcodetype;
  int? barcode;
  DateTime? updatedAt;

  Article({this.title, this.price, this.barcodetype, this.barcode, this.updatedAt});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'barcodetype': barcodetype,
      'barcode': barcode,
      'updatedAt': updatedAt.toString()
    };
  }

  @override
  String toString() {
    return 'Article(title:$title, price:$price, barcodetype:$barcodetype, barcode:$barcode, updatedAt:$updatedAt';
  }
}

class RouteArguments {
  Article article;
  String method;
  RouteArguments({required this.article, required this.method});
}
