# Changelog

## 0.3.9
- Proper error handling with stackTrace support. ([#7](https://github.com/Dreckr/Worker/issues/7))
## 0.3.8
- WorkerIsolate factory. ([#6](https://github.com/Dreckr/Worker/issues/6))

## 0.3.7
  Bug fix.

## 0.3.6
  Minor bug fix.

## 0.3.5
  Bug fix.

## 0.3.4
  Improved isolate selection and load distribution.

## 0.3.3
  Major bug fix.

## 0.3.2
  Major bug fix.

## 0.3.1
  Bug fixes.

## 0.3.0
  Work with new Isolates API.

## 0.2.2
  Minor bug fix.

## 0.2.1
  Bug fixes.

## 0.2.0
Major rewrite:

- Isolates now may handle more than one Task at the time.
- Creation of the WorkerIsolate to abstract comunication with isolates.
- 'execute' method from Worker renamed to 'handle'.
- Workers and WorkerIsolates may be closed.
- Errors are now handled properly.