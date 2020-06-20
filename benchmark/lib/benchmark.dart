import 'package:flutter_cache_manager/src/storage/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';

typedef RepoMaker = Future<CacheInfoRepository> Function();
typedef BenchmarkOperation = Future<void> Function(
    CacheInfoRepository repo, CacheObject sample);

Future<BenchmarkResult> benchmark(
    RepoMaker repoMaker,
    List<CacheObject> samples,
    BenchmarkOperation benchmarkOperation,
    String tag) async {
  // open repo
  final s1 = Stopwatch()..start();
  final cacheInfoRepository = await repoMaker();
  await cacheInfoRepository.open();
  s1.stop();

  // perform some operation
  final n = samples.length;
  final ops = List<int>(n);

  final s2 = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final sOp = Stopwatch()..start();
    await benchmarkOperation(cacheInfoRepository, samples[i]);
    sOp.stop();
    ops[i] = sOp.elapsedMicroseconds;
  }
  s2.stop();

  // close repo
  final s3 = Stopwatch()..start();
  await cacheInfoRepository.close();
  s3.stop();

  return BenchmarkResult(
      tag: tag,
      open: s1.elapsedMicroseconds,
      opsLoop: s2.elapsedMicroseconds,
      ops: ops,
      close: s3.elapsedMicroseconds);
}

/// times in microseconds
class BenchmarkResult {
  BenchmarkResult({this.tag, this.open, this.ops, this.opsLoop, this.close})
      : total = open + opsLoop + close,
        opsAvg = (ops.reduce((a, b) => a + b) / ops.length).round(),
        opsMedian = median(ops);
  final String tag;
  final int open;
  final int opsLoop;
  final List<int> ops;
  final int close;
  final int total;
  final int opsAvg;
  final int opsMedian;

  @override
  String toString() {
    return 'BenchmarkResult(tag: $tag, total: ${total.prettyTime()}, open: ${open.prettyTime()}, opsLoop: ${opsLoop.prettyTime()}, opsAvg: ${opsAvg.prettyTime()}, opsMedian: ${opsMedian.prettyTime()}, close: ${close.prettyTime()})';
  }
}

extension PrettyTime on int {
  String prettyTime() {
    if (this < 10000) {
      return '$this μs';
    } else {
      return '${this / 1000} ms';
    }
  }
}

int median(List<int> unsortedArray) {
  final a = List<int>.from(unsortedArray)..sort();
  final middle = a.length ~/ 2;
  if (a.length % 2 == 1) {
    return a[middle];
  } else {
    return ((a[middle - 1] + a[middle]) / 2.0).round();
  }
}
