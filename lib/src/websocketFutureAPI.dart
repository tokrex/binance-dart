import 'package:binance/data/depth_classes.dart';
import 'package:binance/data/rest_classes.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert' as convert;

class BinanceFAPIWebsocket {
  IOWebSocketChannel _public(String channel) =>
      IOWebSocketChannel.connect(
        'wss://fstream.binance.com/ws/${channel}',
        pingInterval: Duration(minutes: 1),
      );

  Map _toMap(json) => convert.jsonDecode(json);

  List<Map> _toList(json) => List<Map>.from(convert.jsonDecode(json));

  /// Reports book depth
  ///
  /// Levels can be 5, 10, or 20
  ///
  /// https://github.com/binance-exchange/binance-official-api-docs/blob/master/web-socket-streams.md#partial-book-depth-streams
  Stream<Book> fapiBookDepth(String symbol, Book runningBook,
      [int levels = 5]) {
    assert(levels == 5 || levels == 10 || levels == 20);

    // final channel = _public('${symbol.toLowerCase()}@depth$levels@100ms');
    final channel = _public('${symbol.toLowerCase()}@depth@100ms');

    return channel.stream.map((_toMap)).map<Book>((m) => runningBook.update(m));
  }


  Stream fapiBookStream(String symbol) {
    final channel = _public('${symbol.toLowerCase()}@depth@100ms');

    return channel.stream;
  }


  Stream fapiTrades(String symbol) {
    final channel = _public('${symbol.toLowerCase()}@aggTrade');

    return channel.stream;
  }
}
