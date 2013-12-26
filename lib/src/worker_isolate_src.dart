part of worker_src;

ReceivePort localPort;
SendPort mainPort;

void _workerMain (mainPort) {
  if (localPort == null) {
    localPort = new ReceivePort();
  }
  
  if (mainPort is SendPort) {
    mainPort = mainPort;
    mainPort.send(localPort.sendPort);
  }
  
  localPort.listen((message) {
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
  if (message is _WorkerSignal && message.id == CLOSE_SIGNAL.id) {
    localPort.close();
    return false;
  }

  return true;
}