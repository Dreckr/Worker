library worker.test.events;

import 'package:worker/worker.dart';
import 'package:test/test.dart';
import 'common.dart';

void main () {
  group('Event broadcast:', () {
    Worker worker;
    Task task;

    test('of isolate spawned', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);

      worker.onIsolateSpawned.listen(expectAsync1((spawnedEvent) {
        expect(spawnedEvent, TypeMatcher<IsolateSpawnedEvent>());
        expect(spawnedEvent.isolate, TypeMatcher<WorkerIsolate>());
      }));

      worker.close();
    });

    test('of isolate closed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);

      worker.onIsolateClosed.listen(expectAsync1((closedEvent) {
        expect(closedEvent, TypeMatcher<IsolateClosedEvent>());
        expect(closedEvent.isolate, TypeMatcher<WorkerIsolate>());
      }));

      worker.close();
    });

    test('of task scheduled', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new SimpleTask();

      worker.onTaskScheduled.listen(expectAsync1((taskScheduledEvent) {
        expect(taskScheduledEvent, TypeMatcher<TaskScheduledEvent>());
        expect(taskScheduledEvent.task, task);
        expect(taskScheduledEvent.isolate, TypeMatcher<WorkerIsolate>());
      }));

      worker.handle(task);

      worker.close();
    });

    test('of task completed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new SimpleTask();

      worker.onTaskCompleted.listen(expectAsync1((taskCompletedEvent) {
        expect(taskCompletedEvent, TypeMatcher<TaskCompletedEvent>());
        expect(taskCompletedEvent.task, task);
        expect(taskCompletedEvent.result, 'Success');
        expect(taskCompletedEvent.isolate, TypeMatcher<WorkerIsolate>());
      }));

      worker.handle(task);

      worker.close();
    });

    test('of task failed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new ErrorTask();

      worker.onTaskFailed.listen(expectAsync1((taskFailedEvent) {
        expect(taskFailedEvent, TypeMatcher<TaskFailedEvent>());
        expect(taskFailedEvent.task, task);
        expect(taskFailedEvent.error, isNotNull);
        expect(taskFailedEvent.stackTrace, TypeMatcher<StackTrace>());
        expect(taskFailedEvent.isolate, TypeMatcher<WorkerIsolate>());
      }));

      worker.handle(task).then(
          (result) {},
          onError: expectAsync2((error, stackTrace) {})
      );

      worker.close();
    });
  });
}
