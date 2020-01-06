import 'package:binance/data/depth_classes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class fapiRest {

  Future<dynamic> _public(String path, [Map<String, String> params]) async {
    final uri = Uri.https('fapi.binance.com', '$path', params);
    final response = await http.get(uri);

    return response.body; // convert.jsonDecode(response.body);
  }

  /// Order book depth from /v1/depth
  ///
  Future<Book> fapiBook(String symbol, Book runningBook, [int limit = 1000]) =>
      _public('/fapi/v1/depth', {'symbol': '$symbol', 'limit': '$limit'})
          .then((r) => runningBook.init(r));


  Future fapiBookRaw(String symbol, [int limit = 1000]) {
    return _public('/fapi/v1/depth', {'symbol': '$symbol', 'limit': '$limit'});
  }


}

