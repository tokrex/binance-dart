import 'dart:collection';

///
/// Liquidity, Depth
///
/// https://binance-docs.github.io/apidocs/futures/en/#how-to-manage-a-local-order-book-correctly
///
class Book {
  /**
   * Timestamp, internally used to store book
   */
  num time;

  int lastUpdateId;

  /**
   * Indicates if complete book was already fetched by REST API
   */
  bool initiliazed = false;

  /**
   * Indicates if book is initalizing by REST API
   */
  bool isInitializing = false;

  bool bufferUpdates = true;
  List<Map> buffer = List();

  bool mergeUpdate = false;
  int uLast;

  Map<num, num> bid = SplayTreeMap();
  Map<num, num> ask = SplayTreeMap();

  Book init(Map m) {
    this.lastUpdateId = m["lastUpdateId"];

    _mapSide(m["bids"], bid);
    _mapSide(m["asks"], ask);

    initiliazed = true;
    isInitializing = false;

    return this;
  }

  num getAsNum(v) {
    if (v is String)
      return num.parse(v).truncate();
    else
      return v;
  }

  _mapSide(List input, Map target) {
    for (var i = 0; i < input.length; i++) {
      var b = input[i];
      var q = getAsNum(b[1]);
      var p = getAsNum(b[0]);

      if (q == 0)
        target.remove(p);
      else
        target[p] = q;
    }
  }

  Function onBookReady;

  Book update(Map input) {
    if (bufferUpdates) {
      /**
       * Check whether the last real-time data is directly connected to the fetched orderbook
       */
      if (lastUpdateId != null) {
        bufferUpdates = !(input["U"] == lastUpdateId + 1);
        if (!bufferUpdates && onBookReady != null) onBookReady();
      }
    }

    if (bufferUpdates) {
      /**
       * Cache real-time updates until up-to-date with fetched orderbook
       */
      if (lastUpdateId != null) {
        // Drop any event where u is < lastUpdateId in the snapshot.
        if (input["u"] < lastUpdateId) return this;

        // buffer the events you receive from the stream.
        print("buffer.. ${input["U"]} <= $lastUpdateId >= ${input["u"]} ");
        buffer.add(input);

        // first processed event should have U <= lastUpdateId AND u >= lastUpdateId
        if (input["U"] <= lastUpdateId && input["u"] >= lastUpdateId) {
          // from now on, map updates against book
          bufferUpdates = false;
          mergeUpdate = true;
        }
      }
    } else {
      if (mergeUpdate) {
        print("merge..");
        //..first merge, before map latest event
        mergeUpdate = false;
        merge();
        if (onBookReady != null) onBookReady();
      }

      if (input["pu"] != null)
        assert(input["pu"] == uLast, "Synchronization issue.");
      else
        assert(input["U"] == uLast + 1, "Synchronization issue.");

      _mapSide(input["b"], bid);
      _mapSide(input["a"], ask);
    }

    uLast = input["u"];

    return this;
  }

  merge() {
    for (var a = 0; a < buffer.length; a++) {
      _mapSide(buffer[a]["b"], bid);
      _mapSide(buffer[a]["a"], ask);
    }
    buffer.clear();
  }
}

/*
  update(Map m, IBookAggregator aggregator) {
    // this.lastUpdateId = m["u"];

    for (var i = 0; i < m["b"].length; i++) {
      var b = m["b"][i];
      var p = aggregator.aggregate(num.parse(b[0]));
      if (bid[p] == null)
        bid[p] = num.parse(b[1]);
      else
        bid[p] += num.parse(b[1]);
    }

    for (var i = 0; i < m["a"].length; i++) {
      var b = m["a"][i];
      var p = aggregator.aggregate(num.parse(b[0]));
      if (ask[p] == null)
        ask[p] = num.parse(b[1]);
      else
        ask[p] += num.parse(b[1]);
    }
  }
  */
