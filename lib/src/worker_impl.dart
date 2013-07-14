part of worker_src;

class _WorkerImpl implements Worker {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  int poolSize;

  final Queue<WorkerIsolate> isolates = new Queue<WorkerIsolate>();

  Iterable<WorkerIsolate> get availableIsolates => this.isolates.where((isolate) => isolate.isFree);

  Iterable<WorkerIsolate> get workingIsolates => this.isolates.where((isolate) => !isolate.isFree);

  _WorkerImpl ({this.poolSize : 1, spawnLazily : true}) {
    if (this.poolSize <= 0)
      this.poolSize = 1;

    if (!spawnLazily)
      for (var i = 0; i < this.poolSize; i++)
        this.isolates.add(new WorkerIsolate());
  }

  Future handle (Task task) {
    if (this.isClosed)
      throw new Exception('Worker is closed!');

    WorkerIsolate isolate = this._selectIsolate();

    if (isolate != null)
      return isolate.performTask(task);
    else
      throw new Exception("No isolate available");
  }

  WorkerIsolate _selectIsolate () {
    return this.isolates.firstWhere((islt) => islt.isFree,
        orElse:
          () {
            WorkerIsolate isolate;

            if (this.isolates.length < this.poolSize) {
              isolate = new WorkerIsolate();
              this.isolates.add(isolate );

            } else {
              isolate = this.isolates.fold(this.isolates.first,
                  (curr, islt) {
                    if (curr.runningTasks.length < islt.runningTasks.length)
                      return islt;
                    else
                      return curr;
                  });
            }

            return isolate;
        });
  }

  void close () {
    this._isClosed = true;

    this.isolates.forEach((isolate) => isolate.close());
  }

}

class _WorkerIsolateImpl implements WorkerIsolate {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  SendPort sendPort;

  Set<Task> runningTasks = new Set<Task>();

  bool get isFree => runningTasks.isEmpty;

  _WorkerIsolateImpl () {
    this.sendPort = spawnFunction(_workerMain);
  }

  Future performTask (Task task) {
    if (this.isClosed)
      throw new Exception('Isolate is closed!');

    Completer completer = new Completer();

    this.runningTasks.add(task);

    Future taskResult = this.sendPort.call(task);
    taskResult.then(
        (result) {
          if (result is _WorkerError)
            completer.completeError(result.error);
          else
            completer.complete(result);
        },
        onError: (exception) => completer.completeError(exception));

    taskResult.whenComplete(
      () {
          this.runningTasks.remove(task);
      });

    return completer.future;
  }

  void close () {
    sendPort.call(CLOSE_SIGNAL);
  }

}


/**
 * Signals:
 *  1 - CloseIsolate
 */
const CLOSE_SIGNAL = const _WorkerSignal(1);
class _WorkerSignal {
  final int id;

  const _WorkerSignal (this.id);

}

class _WorkerError {
  var error;

  _WorkerError (this.error);
}