part of worker_src;

ReceivePort nativeReceivePort;
SendPort nativeSendPort;
bool flag = false;
Map<int, IsolatedReceivePort> isolatedReceivePorts = new Map();

void prepareReceivePort () {
  nativeReceivePort = new ReceivePort();
  nativeSendPort = nativeReceivePort.sendPort;
  nativeReceivePort.listen(
      (data) {
        if (data is IsolatedMessage &&
            isolatedReceivePorts.containsKey(data.id)) {
          isolatedReceivePorts[data.id]._controller.add(data.message);
        }
      });
  flag = true;
}

class IsolatedReceivePort extends Stream implements ReceivePort {
  static int nextId = 1;
  int id;
  IsolatedSendPort _sendPort;
  SendPort get sendPort => _sendPort;
  StreamController _controller = new StreamController();
  StreamSubscription _subscription;
  
  IsolatedReceivePort () {
    if (!flag) {
      prepareReceivePort();
    }
    
    this.id = nextId;
    nextId++;
    
    _sendPort = new IsolatedSendPort(id);
    
    isolatedReceivePorts[id] = this;
  }
  
  StreamSubscription listen(void onData(value),
                            { void onError(error),
    void onDone(),
    bool cancelOnError }) {
    
    return this._controller.stream.listen(
          onData, 
          onError: onError, 
          onDone: onDone,
          cancelOnError: cancelOnError);
  }
  
  void close() {
    _subscription.cancel();
  }
}

class IsolatedSendPort implements SendPort {
  int id;
  SendPort _sendPort;

  IsolatedSendPort(int this.id) : _sendPort = nativeSendPort;
  
  void send (message) {
    _sendPort.send(new IsolatedMessage(id, message));
  }
}

class IsolatedMessage {
  int id;
  var message;
  
  IsolatedMessage (this.id, this.message);
}

class _WorkerImpl implements Worker {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  int poolSize;

  final Queue<WorkerIsolate> isolates = new Queue<WorkerIsolate>();

  Iterable<WorkerIsolate> get availableIsolates => 
      this.isolates.where((isolate) => isolate.isFree);

  Iterable<WorkerIsolate> get workingIsolates => 
      this.isolates.where((isolate) => !isolate.isFree);

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
              isolate = this.isolates.firstWhere(
                  (isolate) => isolate.isFree,
                  orElse: () => this.isolates.single);
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
  
  ReceivePort _receivePort;

  SendPort _sendPort;
  
  Queue<_ScheduledTask> _scheduledTasks = new Queue<_ScheduledTask>();

  _ScheduledTask _runningScheduledTask;
  
  bool get isFree => _scheduledTasks.isEmpty && _runningScheduledTask == null;

  _WorkerIsolateImpl () {
    this._receivePort = new IsolatedReceivePort();
    Isolate.spawn(_workerMain, this._receivePort.sendPort).then(
        (isolate) {
        }, onError: (error) {
          print(error);
        });
    
    this._receivePort.listen((message) {
      if (message is SendPort) {
        this._sendPort = message;
        this._runNextTask();
        return;
      }
      
      if (message is _WorkerError) {
        this._runningScheduledTask.completer.completeError(message.error);
      } else if (message != null) {
        this._runningScheduledTask.completer.complete(message);
      }
      
      this._runNextTask();
    },
    onError: (exception) {
        this._runningScheduledTask.completer.completeError(exception);
      }
    );
    
  }

  Future performTask (Task task) {
    if (this.isClosed)
      throw new Exception('Isolate is closed!');
    
    Completer completer = new Completer();
    _scheduledTasks.add(new _ScheduledTask(task, completer));
    
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

  void close () {
    _sendPort.send(CLOSE_SIGNAL);
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
const CLOSE_SIGNAL = const _WorkerSignal(1);
class _WorkerSignal {
  final int id;

  const _WorkerSignal (this.id);

}

class _WorkerError {
  var error;

  _WorkerError (this.error);
}
