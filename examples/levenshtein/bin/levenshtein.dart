import 'dart:async';
import 'dart:io';
import 'package:levenshtein/levenshtein.dart';
import 'package:worker/src/worker.dart';


void main() {
  var worker = new Worker(spawnLazily: false);
  
  var input = "This is a pretty lame test string, but it is one that works!";
  var stringList = new List.filled(500, "This is another test string");
  stringList[499] = "$input You see?!";
  
  var futures = new List<Future>();
  
  var sublistLength = stringList.length / Platform.numberOfProcessors;
  for (var i = 0; i < Platform.numberOfProcessors; i++) {
    var start = i * sublistLength;
    var end = start + sublistLength;
    end = end <= stringList.length ? end : stringList.length;
    
    var sublist = stringList.sublist(start.floor(), end.floor());
    futures.add(worker.handle(new LevenshteinTask(input, sublist)));
  }

  Future.wait(futures).then(
    (results) {
      var result = results.reduce(
          (a, b) => a.closestDistance <= b.closestDistance ? a : b);
      
      print("Closest String to '$input': '${result.closestString}\n"
            "Levenshtein distance: ${result.closestDistance}");
      
      worker.close();
    });
}

class LevenshteinTask extends Task {
  String input;
  List<String> stringList;
  
  LevenshteinTask(this.input, this.stringList);
  
  Future<LevenshteinResult> execute() {
    var closestWord;
    var closestDistance = double.INFINITY;
    
    stringList.forEach((word) {
      var distance = levenshtein(input, word);
      
      if (distance < closestDistance) {
        closestWord = word;
        closestDistance = distance;
      }
    });
    
    return 
        new Future.value(new LevenshteinResult(closestWord, closestDistance));
  }
}

class LevenshteinResult {
  String closestString;
  int closestDistance;
  
  LevenshteinResult(this.closestString, this.closestDistance);
}