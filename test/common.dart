library worker.test.common;

import 'dart:async';
import 'package:worker/worker.dart';


class AddTask implements Task<int> {
  int x, y;
  bool throwException;

  AddTask (this.x, this.y, {this.throwException: false});

  int execute () {
    if (this.throwException)
      throw new Exception('Test Future Exception');
    else
      return x + y;
  }
}

class AsyncAddTask implements Task<Future<int>> {
  int x, y;
  bool throwException;

  AsyncAddTask (this.x, this.y, {this.throwException: false});

  Future<int> execute () {
    final completer = new Completer<int>();

    scheduleMicrotask(() {
      if (this.throwException)
        completer.completeError(new Exception('Test Async Exception'));
      else
        completer.complete(x + y);
      });

    return completer.future;
  }

}

class SimpleTask implements Task<String> {

  String execute() {
    return 'Success';
  }
}

class ErrorTask implements Task<int> {

  int execute() {
    throw new Error();
  }
}

class NoReturnTask implements Task {

  void execute() {
    var a = 1;
    var b = 2;
    var c = a + b;
  }
}

class LongRunningTask extends Task<bool> {

  bool execute() {
    var stopWatch = new Stopwatch();
    stopWatch.start();

    while(stopWatch.elapsedMilliseconds < 1000);
    stopWatch.stop();

    return true;
  }
}
