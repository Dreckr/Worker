part of worker;

void _workerMain (sendPort) {
  ReceivePort receivePort;
  if (receivePort == null) {
    receivePort = new ReceivePort();
  }

  if (sendPort is SendPort) {
    sendPort = sendPort;
    sendPort.send(receivePort.sendPort);
  }

  receivePort.listen((message) {
    if (!_acceptMessage(receivePort, message))
        return;

    var result;

    try {
      if (message is Task) {
          result = message.execute();

          if (result is Future) {
            result.then(
                (futureResult) =>
                    sendPort.send(new _WorkerResult(futureResult)),
                onError: (exception, stackTrace) =>
                    sendException(sendPort, exception, stackTrace));
          } else {
            sendPort.send(new _WorkerResult(result));
          }
      } else
        throw new Exception('Message is not a task');
    } catch (exception, stackTrace) {
      sendException(sendPort, exception, stackTrace);
    }
  });
}

bool _acceptMessage (ReceivePort receivePort, message) {
  if (message is _WorkerSignal && message.id == _CLOSE_SIGNAL.id) {
    receivePort.close();
    return false;
  }

  return true;
}

void sendException (SendPort sendPort, exception, StackTrace stackTrace) {
  if (exception is Error) {
    exception = Error.safeToString(exception);
  }

  var stackTraceFrames;
  if (stackTrace != null) {
    stackTraceFrames = new Trace.from(stackTrace).frames;
  }

  sendPort.send(
      new _WorkerException(exception, stackTraceFrames));
}