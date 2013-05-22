part of worker_src;


void _workerMain () {
  port.receive((message, SendPort sendPort) {
    if (!_acceptMessage(message))
        return;
    
    if (message is Task)  {
      var result;

      try {
        result = message.execute();
      } catch (exception) {
        sendPort.call(new _WorkerError(exception));
      }

      if (result is Future) {
        result.then(
            (futureResult) => sendPort.send(futureResult),
            onError: (exception) => sendPort.call(new _WorkerError(exception)));
      } else {
        sendPort.send(result);
      }
    } else
      sendPort.call(new _WorkerError(new Exception('Message is not a task')));
  });
}

bool _acceptMessage (message) {
  if (message == const _WorkerSignal(1)) {
    port.close();
    return false;
  }
  
  return true;
}