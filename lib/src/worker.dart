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

class Worker {

  int poolSize;
  Queue<SendPort> availableSendPorts = new Queue<SendPort>();
  Set<SendPort> workingSendPorts = new Set<SendPort>();
  Queue<WaitingTask> waitingTasks = new Queue<WaitingTask>();
  bool _closed = false;

  Worker ({this.poolSize : 1}) {
    if (this.poolSize <= 0)
      this.poolSize = 1;
  }

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

      if (waitingTasks.length == 0) {
        availableSendPorts.add(sendPort);
      } else {
        WaitingTask waitingTask = waitingTasks.removeFirst();
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
    waitingTasks.add(new WaitingTask(task, completer));
  }

}

class WaitingTask {
  Task task;
  Completer completer;

  WaitingTask (this.task, this.completer);
}

abstract class Task<T> {

  T execute ();

}