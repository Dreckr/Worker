library worker.test.execution;

import 'package:worker/worker.dart';
import 'package:unittest/unittest.dart';
import 'common.dart';

void executionTest () {
  group('Task execution:', () {
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

      worker.handle(task).then(expectAsync((result) {
        expect(result, equals(3));
      }));
    });

    test('of sync task with exception', () {
      task = new AddTask(1, 2, throwException: true);


      worker.handle(task).then(
          (result) {},
      onError: expectAsync(
          (error) => expect(error, isNotNull)));
    });

    test('of async task', () {
      task = new AsyncAddTask(3, 2);

      worker.handle(task).then(expectAsync((result) {
        expect(result, equals(5));
      }));
    });

    test('of async task with exception', () {
      task = new AsyncAddTask(1, 2, throwException: true);

      worker.handle(task).then(
          (result) {},
          onError: expectAsync(
              (error) => expect(error, isNotNull))
      );

    });

    test('of task with error', () {
      task = new ErrorTask();

      worker.handle(task).then(
          (result) {},
          onError: expectAsync((error, stackTrace) {
            expect(error, isNotNull);
            expect(stackTrace, new isInstanceOf<StackTrace>());
          })
      );

    });

    test('of task with no return', () {
      task = new NoReturnTask();

      var future = worker.handle(task);

      expect(future, completes);
    });

  });
}
