library worker;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'package:stack_trace/stack_trace.dart';

part 'worker_impl.dart';
part 'worker_isolate_src.dart';

/**
 * A concurrent [Task] executor.
 *
 * A [Worker] creates and manages a pool of isolates providing you with an easy
 * way to perform blocking tasks concurrently. It spawns isolates lazilly as [Task]s
 * are required to execute.
 */

abstract class Worker {
  bool get isClosed;

  /// Size of the pool of isolates.
  int poolSize;

  /// All spawned isolates
  Queue<WorkerIsolate> get isolates;

  /// Spawned isolates that are free to handle more tasks.
  Iterable<WorkerIsolate> get availableIsolates;

  /// Isolates that are currently performing a task.
  Iterable<WorkerIsolate> get workingIsolates;

  factory Worker ({int poolSize, bool spawnLazily : true}) {
    if (poolSize == null) {
      poolSize = Platform.numberOfProcessors;
    }

    return new _WorkerImpl(poolSize: poolSize, spawnLazily: spawnLazily);
  }

  /// Returns a [Future] with the result of the execution of the [Task].
  Future handle (Task task);

  /// Closes the [ReceivePort] of the isolates;
  void close ();

}

/**
 * A representation of an isolate
 *
 * A representation of an isolate containing a [SendPort] to it and the tasks
 * that are running on it.
 */
abstract class WorkerIsolate {
  bool get isClosed;
  bool get isFree;
  Task get runningTask;
  List<Task> get scheduledTasks;

  factory WorkerIsolate() => new _WorkerIsolateImpl();

  Future performTask (Task task);

  /// Closes the [ReceivePort] of the isolate;
  void close ();
}

/**
 * A task that needs to be executed.
 *
 * This class provides an interface for tasks.
 */
abstract class Task<T> {

  T execute ();

}