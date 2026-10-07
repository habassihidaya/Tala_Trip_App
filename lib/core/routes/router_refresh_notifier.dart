import 'dart:async';

import 'package:flutter/foundation.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  final List<StreamSubscription<Object?>> _subscriptions = [];

  RouterRefreshNotifier(
    Stream<Object?> stream, {
    List<Stream<Object?>> additionalStreams = const [],
  }) {
    for (final source in [stream, ...additionalStreams]) {
      _subscriptions.add(
        source.listen((_) {
          notifyListeners();
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }
}
