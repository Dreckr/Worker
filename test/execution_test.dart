library worker.test.execution;

import 'dart:async';
import 'package:worker/worker.dart';
import 'package:unittest/unittest.dart';

void executionTest() {
  group ('Task execution:', () {
    Worker worker;
    Task task;

    setUp(() {
      worker = new Worker();
    });
    
    tearDown(() {
      worker.close();
    });

    test('of sync task', () {
      task = new AddTask(1, 2);

      worker.handle(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(3));
      }));
    });

    test('of sync task with exception', () {
      task = new AddTask(1, 2, throwException: true);


      worker.handle(task).then((result) {
      },
      onError: expectAsync1((error) {
        expect(error, isNotNull);
      })
      );
    });

    test('of async task', () {
      task = new AsyncAddTask(3, 2);

      worker.handle(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(5));
      }));
    });

    test('of async task with exception', () {
      task = new AsyncAddTask(1, 2, throwException: true);

      worker.handle(task).then((result) {
      },
      onError: expectAsync1((error) {
        expect(error, isNotNull);
      })
      );

    });

  });
}

class AddTask implements Task {
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

class AsyncAddTask implements Task {
  int x, y;
  bool throwException;

  AsyncAddTask (this.x, this.y, {this.throwException: false});

  Future execute () {
    Completer completer = new Completer();

    scheduleMicrotask(() {
      if (this.throwException)
        completer.completeError(new Exception('Test Async Exception'));
      else
        completer.complete(x + y);
      });

    return completer.future;
  }

}
