part of worker;

ReceivePort _localPort;
SendPort _mainPort;

void _workerMain (mainPort) {
  if (_localPort == null) {
    _localPort = new ReceivePort();
  }
  
  if (mainPort is SendPort) {
    mainPort = mainPort;
    mainPort.send(_localPort.sendPort);
  }
  
  _localPort.listen((message) {
    if (!_acceptMessage(message))
        return;
  
    if (message is Task) {
      var result;
  
      try {
        result = message.execute();
      } catch (exception) {
        mainPort.send(new _WorkerError(exception));
      }
  
      if (result is Future) {
        result.then(
            (futureResult) => mainPort.send(futureResult),
            onError: (exception) => mainPort.send(new _WorkerError(exception)));
      } else {
        mainPort.send(result);
      }
    } else
      mainPort.send(new _WorkerError(new Exception('Message is not a task')));
  });
}

bool _acceptMessage (message) {
  if (message is _WorkerSignal && message.id == _CLOSE_SIGNAL.id) {
    _localPort.close();
    return false;
  }

  return true;
}