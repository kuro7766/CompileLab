import 'dart:async';

void main() {
  StreamController streamController = StreamController();
  for (var i = 0; i < 5; i++) {
    streamController.add(i);
  }
  StreamSubscription sub;

  sub = streamController.stream.listen((event) async {
    print(event);
    sub.pause();
    await Future.delayed(Duration(seconds: 1));
    sub.resume();
  });
}
