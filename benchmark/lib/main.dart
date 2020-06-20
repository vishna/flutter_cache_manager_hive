import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object_provider.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager_hive/flutter_cache_manager_hive.dart';
import 'package:flutter_cache_manager_hive/src/hive_cache_object_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'benchmark.dart';

void main() {
  Hive.initFlutter();
  Hive.registerAdapter(CacheObjectAdapter(typeId: 1));
  runApp(MyApp());
  DefaultCacheManager();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cache Store Benchmark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Cache Store Benchmark'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BenchmarkResult> _results;

  Future<void> _runBenchmark() async {
    await cleanRepo(sqflite);
    await cleanRepo(hive);

    final urls = List<String>.generate(
        1000, (index) => 'https://blurha.sh/assets/images/img$index.jpg');
    final validTill = DateTime.now().add(const Duration(days: 30));

    final samplesSqflite = urls
        .map<CacheObject>((url) => CacheObject(url,
            relativePath: '/relative/$url',
            validTill: validTill,
            eTag: url.hashCode.toString()))
        .toList();

    final samplesHive = urls
        .map<CacheObject>((url) => CacheObject(url,
            id: url.hashCode,
            relativePath: '/relative/$url',
            validTill: validTill,
            eTag: url.hashCode.toString()))
        .toList();

    final samplesMap = {'sqflite': samplesSqflite, 'hive': samplesHive};

    final opMap = {'write': opWrite, 'read': opRead, 'delete': opDelete};

    final repoMap = {'sqflite': sqflite, 'hive': hive};

    final results = <BenchmarkResult>[];
    for (final repoKey in ['sqflite', 'hive']) {
      for (final opKey in ['write', 'read', 'delete']) {
        results.add(await benchmark(repoMap[repoKey], samplesMap[repoKey],
            opMap[opKey], '$repoKey:$opKey'));
      }
    }

    results.forEach(print);

    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _results == null
          ? const Center(
              child: Text('Tap Timer to measure cache store performance'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tag,
                            style: const TextStyle(fontSize: 18.0),
                          ),
                          Text(
                              'Operation Average: ${item.opsAvg.prettyTime()}'),
                          Text('Operation Median: ${item.opsAvg.prettyTime()}')
                        ]),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: _runBenchmark,
        tooltip: 'Measure',
        child: Icon(Icons.timer),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

final BenchmarkOperation opWrite = (repo, sample) async {
  await repo.updateOrInsert(sample);
};

final BenchmarkOperation opRead = (repo, sample) async {
  final cacheObject = await repo.get(sample.url);
  if (cacheObject == null) {
    throw StateError(
        'cacheObject null for url=${sample.url} for repo ${repo.runtimeType}');
  }
  if (cacheObject.url != sample.url) {
    throw StateError('url mismatch for repo ${repo.runtimeType}');
  }
};

final BenchmarkOperation opDelete = (repo, sample) async {
  await repo.delete(sample.id);
};

final RepoMaker sqflite = () async {
  final databasesPath = await getDatabasesPath();
  try {
    await Directory(databasesPath).create(recursive: true);
  } catch (_) {}
  final path = p.join(databasesPath, 'image-cache.db');
  return CacheObjectProvider(path);
};

final RepoMaker hive = () async {
  return HiveCacheObjectProvider(Hive.openBox('image-caching-box'));
};

Future<void> cleanRepo(RepoMaker r) async {
  final repository = await r.call();

  await repository.open();
  final ids =
      (await repository.getAllObjects()).map<int>((co) => co.id).toList();
  print('Deleteing ${ids.length} items from ${repository.runtimeType}');
  await repository.deleteAll(ids);
  await repository.close();
}
