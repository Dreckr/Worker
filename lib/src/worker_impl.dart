part of worker;

class _WorkerImpl implements Worker {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  int poolSize;

  final Queue<WorkerIsolate> isolates = new Queue<WorkerIsolate>();

  Iterable<WorkerIsolate> get availableIsolates =>
      this.isolates.where((isolate) => isolate.isFree);

  Iterable<WorkerIsolate> get workingIsolates =>
      this.isolates.where((isolate) => !isolate.isFree);

  StreamController<IsolateSpawnedEvent> _isolateSpawnedEventController =
      new StreamController<IsolateSpawnedEvent>.broadcast();

  Stream<IsolateSpawnedEvent> get onIsolateSpawned =>
      _isolateSpawnedEventController.stream;

  StreamController<IsolateClosedEvent> _isolateClosedEventController =
      new StreamController<IsolateClosedEvent>.broadcast();

  Stream<IsolateClosedEvent> get onIsolateClosed =>
      _isolateClosedEventController.stream;

  StreamController<TaskScheduledEvent> _taskScheduledEventController =
      new StreamController<TaskScheduledEvent>.broadcast();

  Stream<TaskScheduledEvent> get onTaskScheduled =>
      _taskScheduledEventController.stream;

  StreamController<TaskCompletedEvent> _taskCompletedEventController =
      new StreamController<TaskCompletedEvent>.broadcast();

  Stream<TaskCompletedEvent> get onTaskCompleted =>
      _taskCompletedEventController.stream;

  StreamController<TaskFailedEvent> _taskFailedEventController =
      new StreamController<TaskFailedEvent>.broadcast();

  Stream<TaskFailedEvent> get onTaskFailed =>
      _taskFailedEventController.stream;

  _WorkerImpl ({this.poolSize : 1, spawnLazily : true}) {
    if (this.poolSize <= 0)
      this.poolSize = 1;

    if (!spawnLazily) {
      for (var i = 0; i < this.poolSize; i++) {
        this._spawnIsolate();
      }
    }
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
            var isolate;

            if (this.isolates.length < this.poolSize) {
              isolate = this._spawnIsolate();
            } else {
              isolate = this.isolates.firstWhere(
                  (isolate) => isolate.isFree,
                  orElse: () => this.isolates.reduce(
                      (a, b) =>
                          a.scheduledTasks.length <= b.scheduledTasks.length ?
                              a : b));
            }

            return isolate;
        });
  }

  WorkerIsolate _spawnIsolate () {
    var isolate = new _WorkerIsolateImpl();
    mergeStream(_isolateSpawnedEventController, isolate.onSpawned);
    mergeStream(_isolateClosedEventController, isolate.onClosed);
    mergeStream(_taskScheduledEventController, isolate.onTaskScheduled);
    mergeStream(_taskCompletedEventController, isolate.onTaskCompleted);
    mergeStream(_taskFailedEventController, isolate.onTaskFailed);
    this.isolates.add(isolate );

    return isolate;
  }

  void close () {
    this._isClosed = true;

    this.isolates.forEach((isolate) => isolate.close());
  }

}

class _WorkerIsolateImpl implements WorkerIsolate {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  ReceivePort _receivePort;

  SendPort _sendPort;

  Queue<_ScheduledTask> _scheduledTasks = new Queue<_ScheduledTask>();

  _ScheduledTask _runningScheduledTask;

  Task get runningTask => _runningScheduledTask != null ?
                            _runningScheduledTask.task : null;

  List<Task> get scheduledTasks =>
      _scheduledTasks.map((scheduledTask) => scheduledTask.task)
        .toList(growable: false);

  bool get isFree => _scheduledTasks.isEmpty && _runningScheduledTask == null;

  StreamController<IsolateSpawnedEvent> _spawnEventController =
      new StreamController<IsolateSpawnedEvent>.broadcast();

  Stream<IsolateSpawnedEvent> get onSpawned =>
      _spawnEventController.stream;

  StreamController<IsolateClosedEvent> _closeEventController =
      new StreamController<IsolateClosedEvent>.broadcast();

  Stream<IsolateClosedEvent> get onClosed =>
      _closeEventController.stream;

  StreamController<TaskScheduledEvent> _taskScheduledEventController =
      new StreamController<TaskScheduledEvent>.broadcast();

  Stream<TaskScheduledEvent> get onTaskScheduled =>
      _taskScheduledEventController.stream;

  StreamController<TaskCompletedEvent> _taskCompletedEventController =
      new StreamController<TaskCompletedEvent>.broadcast();

  Stream<TaskCompletedEvent> get onTaskCompleted =>
      _taskCompletedEventController.stream;

  StreamController<TaskFailedEvent> _taskFailedEventController =
      new StreamController<TaskFailedEvent>.broadcast();

  Stream<TaskFailedEvent> get onTaskFailed =>
      _taskFailedEventController.stream;

  _WorkerIsolateImpl () {
    this._receivePort = new ReceivePort();

    this._spawnIsolate();
  }

  Future<WorkerIsolate> _spawnIsolate () {
    Completer<WorkerIsolate> completer = new Completer();
    Isolate.spawn(_workerMain, this._receivePort.sendPort).then(
          (isolate) {
          }, onError: (error) {
            print(error);
          });

      this._receivePort.listen((message) {
        if (message is SendPort) {
          completer.complete(this);
          this._spawnEventController.add(new IsolateSpawnedEvent(this));
          this._sendPort = message;
          this._runNextTask();
          return;
        }

        if (message is _WorkerException) {
          this._taskFailedEventController.add(
              new TaskFailedEvent(this,
                                  this._runningScheduledTask.task,
                                  message.exception,
                                  message.stackTrace));

          this._runningScheduledTask.completer
            .completeError(message.exception, message.stackTrace);
        } else if (message is _WorkerSignal) {
          if (message.id == _CLOSE_SIGNAL.id){
            this._closeEventController.add(new IsolateClosedEvent(this));
            this._closeStreamControllers();
            _receivePort.close();
          }
        } else if (message is _WorkerResult) {
          this._taskCompletedEventController.add(
              new TaskCompletedEvent( this,
                                      this._runningScheduledTask.task,
                                      message.result));

          this._runningScheduledTask.completer.complete(message.result);
        }

        this._runningScheduledTask = null;

        this._runNextTask();
      },
      onError: (exception) {
          this._runningScheduledTask.completer.completeError(exception);
          this._runningScheduledTask = null;
        }
      );

      return completer.future;
  }

  Future performTask (Task task) {
    if (this.isClosed)
      throw new Exception('Isolate is closed!');

    this._taskScheduledEventController.add(new TaskScheduledEvent(this, task));
    Completer completer = new Completer();
    this._scheduledTasks.add(new _ScheduledTask(task, completer));

    this._runNextTask();

    return completer.future;
  }

  void _runNextTask () {
    if (_sendPort == null ||
        _scheduledTasks.length == 0 ||
        (_runningScheduledTask != null &&
        !_runningScheduledTask.completer.isCompleted))
      return;

    _runningScheduledTask = _scheduledTasks.removeFirst();

    this._sendPort.send(_runningScheduledTask.task);

  }

  void _closeStreamControllers () {
    this._spawnEventController.close();
    this._closeEventController.close();
    this._taskScheduledEventController.close();
    this._taskCompletedEventController.close();
    this._taskFailedEventController.close();
  }

  void close () {
    if (this._sendPort == null) {
      this._closeEventController.add(new IsolateClosedEvent(this));
      return;
    }

    _sendPort.send(_CLOSE_SIGNAL);
  }

}

class _ScheduledTask {
  Completer completer;
  Task task;

  _ScheduledTask (Task this.task, Completer this.completer);
}


/**
 * Signals:
 *  1 - CloseIsolate
 */
const _CLOSE_SIGNAL = const _WorkerSignal(1);
class _WorkerSignal {
  final int id;

  const _WorkerSignal (this.id);

}

class _WorkerResult {
  final result;

  _WorkerResult (this.result);
}

class _WorkerException {
  final exception;
  final List<Frame> stackTraceFrames;
  StackTrace get stackTrace {
    if (stackTraceFrames != null) {
      return new Trace(stackTraceFrames).vmTrace;
    }

    return null;
  }

  _WorkerException (this.exception, this.stackTraceFrames);
}

void mergeStream (EventSink sink, Stream stream) {
  stream.listen(
      (data) => sink.add(data),
      onError: (errorEvent, stackTrace) =>
          sink.addError(errorEvent, stackTrace));
}