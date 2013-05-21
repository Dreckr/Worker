library worker_src;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

void _workerMain () {
  port.receive((message, SendPort sendPort) {
    if (message is Task)  {
      var result;

      try {
        result = message.execute();
      } catch (exception) {
        throw exception;
      }

      if (result is Future) {
        result.then(
            (futureResult) => sendPort.send(futureResult),
            onError: (exception) => throw exception);
      } else {
        sendPort.send(result);
      }
    } else
      throw new Exception('Message sent to isolate worker is not a Task');
  });
}

/**
 * A concurrent [Task] executor.
 * 
 * A [Worker] creates and manages a pool of isolates providing you with an easy 
 * way to perform blocking tasks concurrently. It spawns isolates lazilly as [Task]s
 * are required to execute.
 */
class Worker {
  // TODO Provide a way to close isolates
  // TODO Tasks don't have to actually wait for a free isolate. They can run side-by-side with other tasks.

  /// Size of the pool of isolates.
  int poolSize;
  
  /// Spawned isolates that free to handle more tasks.
  Queue<SendPort> availableSendPorts = new Queue<SendPort>();
  
  /// Isolates that are currently performing a task.
  Set<SendPort> workingSendPorts = new Set<SendPort>();
  
  /// Tasks that are waiting for a free isolate.
  Queue<_WaitingTask> _waitingTasks = new Queue<_WaitingTask>();

  Worker ({this.poolSize : 1}) {
    if (this.poolSize <= 0)
      this.poolSize = 1;
  }

  /// Returns a [Future] with the result of the execution of the [Task].
  Future execute (Task task) {
    Completer completer = new Completer();
    SendPort sendPort = _getAvailableSendPort();

    if (sendPort != null)
      this._runTask(sendPort, task, completer);
    else
      this._queueTask(task, completer);

    return completer.future;
  }

  void _runTask (SendPort sendPort, Task task, Completer completer) {
    workingSendPorts.add(sendPort);
    Future taskResult = sendPort.call(task);
    taskResult.then(
        (result) => completer.complete(result),
        onError: (exception) => completer.completeError(exception));

    taskResult.whenComplete(() {
      workingSendPorts.remove(sendPort);

      if (_waitingTasks.length == 0) {
        availableSendPorts.add(sendPort);
      } else {
        _WaitingTask waitingTask = _waitingTasks.removeFirst();
        this._runTask(sendPort, waitingTask.task, waitingTask.completer);
      }
    });
  }

  SendPort _getAvailableSendPort () {
    SendPort sendPort;

    if (this.availableSendPorts.length > 0)
      sendPort = this.availableSendPorts.removeFirst();
    else if (this.workingSendPorts.length < poolSize)
      sendPort = spawnFunction(_workerMain); // TODO Handle exceptions

    return sendPort;
  }

  void _queueTask (Task task, Completer completer) {
    _waitingTasks.add(new _WaitingTask(task, completer));
  }

}

class _WaitingTask {
  Task task;
  Completer completer;

  _WaitingTask (this.task, this.completer);
}


/**
 * A task that needs to be executed.
 * 
 * This class provides an interface for tasks.
 */
abstract class Task<T> {

  T execute ();

}