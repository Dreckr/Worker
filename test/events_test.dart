library worker.test.events;

import 'package:worker/worker.dart';
import 'package:unittest/unittest.dart';
import 'common.dart';

void eventsTest () {
  group('Event broadcast:', () {
    Worker worker;
    Task task;

    test('of isolate spawned', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);

      worker.onIsolateSpawned.listen(expectAsync((spawnedEvent) {
        expect(spawnedEvent, new isInstanceOf<IsolateSpawnedEvent>());
        expect(spawnedEvent.isolate, new isInstanceOf<WorkerIsolate>());
      }));

      worker.close();
    });

    test('of isolate closed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);

      worker.onIsolateClosed.listen(expectAsync((closedEvent) {
        expect(closedEvent, new isInstanceOf<IsolateClosedEvent>());
        expect(closedEvent.isolate, new isInstanceOf<WorkerIsolate>());
      }));

      worker.close();
    });

    test('of task scheduled', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new SimpleTask();

      worker.onTaskScheduled.listen(expectAsync((taskScheduledEvent) {
        expect(taskScheduledEvent, new isInstanceOf<TaskScheduledEvent>());
        expect(taskScheduledEvent.task, task);
        expect(taskScheduledEvent.isolate, new isInstanceOf<WorkerIsolate>());
      }));

      worker.handle(task);

      worker.close();
    });

    test('of task completed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new SimpleTask();

      worker.onTaskCompleted.listen(expectAsync((taskCompletedEvent) {
        expect(taskCompletedEvent, new isInstanceOf<TaskCompletedEvent>());
        expect(taskCompletedEvent.task, task);
        expect(taskCompletedEvent.result, 'Success');
        expect(taskCompletedEvent.isolate, new isInstanceOf<WorkerIsolate>());
      }));

      worker.handle(task);

      worker.close();
    });

    test('of task failed', () {
      worker = new Worker(poolSize: 1, spawnLazily: false);
      task = new ErrorTask();

      worker.onTaskFailed.listen(expectAsync((taskFailedEvent) {
        expect(taskFailedEvent, new isInstanceOf<TaskFailedEvent>());
        expect(taskFailedEvent.task, task);
        expect(taskFailedEvent.error, isNotNull);
        expect(taskFailedEvent.stackTrace, new isInstanceOf<StackTrace>());
        expect(taskFailedEvent.isolate, new isInstanceOf<WorkerIsolate>());
      }));

      worker.handle(task).then(
          (result) {},
          onError: expectAsync((error, stackTrace) {})
      );

      worker.close();
    });
  });
}
