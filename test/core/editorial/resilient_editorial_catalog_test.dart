import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/core/editorial/editorial_local_catalog.dart';
import 'package:atlas/core/editorial/editorial_remote_catalog.dart';
import 'package:atlas/core/editorial/resilient_editorial_catalog.dart';

void main() {
  group('ResilientEditorialCatalog', () {
    test('sert le local avant warmUp', () {
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a', 'local-b'],
        fetchRemote: () async => const ['remote-a'],
      );

      expect(catalog.loadState, EditorialCatalogLoadState.idle);
      expect(catalog.isUsingRemote, isFalse);
      expect(catalog.items, ['local-a', 'local-b']);
    });

    test('utilise le distant quand le fetch réussit', () async {
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchRemote: () async => const ['remote-a', 'remote-b'],
      );

      var notifications = 0;
      catalog.addListener(() => notifications++);

      await catalog.warmUp();

      expect(catalog.loadState, EditorialCatalogLoadState.readyRemote);
      expect(catalog.isUsingRemote, isTrue);
      expect(catalog.items, ['remote-a', 'remote-b']);
      expect(notifications, greaterThanOrEqualTo(1));
    });

    test('retombe sur le local si le distant échoue', () async {
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchRemote: () async => throw Exception('network error'),
      );

      await catalog.warmUp();

      expect(catalog.loadState, EditorialCatalogLoadState.readyLocalFallback);
      expect(catalog.isUsingRemote, isFalse);
      expect(catalog.items, ['local-a']);
    });

    test('retombe sur le local si le distant est vide', () async {
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchRemote: () async => const [],
      );

      await catalog.warmUp();

      expect(catalog.loadState, EditorialCatalogLoadState.readyLocalFallback);
      expect(catalog.isUsingRemote, isFalse);
      expect(catalog.items, ['local-a']);
    });

    test('retombe sur le local si le distant dépasse le délai', () async {
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchTimeout: const Duration(milliseconds: 20),
        fetchRemote: () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const ['remote-a'];
        },
      );

      await catalog.warmUp();

      expect(catalog.loadState, EditorialCatalogLoadState.readyLocalFallback);
      expect(catalog.items, ['local-a']);
    });

    test('warmUp est idempotent', () async {
      var fetchCount = 0;
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchRemote: () async {
          fetchCount++;
          return const ['remote-a'];
        },
      );

      await catalog.warmUp();
      await catalog.warmUp();

      expect(fetchCount, 1);
      expect(catalog.items, ['remote-a']);
    });

    test('passe par loading pendant le fetch', () async {
      final gate = Completer<void>();
      final catalog = ResilientEditorialCatalog<String>(
        localItems: const ['local-a'],
        fetchRemote: () async {
          await gate.future;
          return const ['remote-a'];
        },
      );

      final pending = catalog.warmUp();
      await Future<void>.delayed(Duration.zero);

      expect(catalog.loadState, EditorialCatalogLoadState.loading);
      expect(catalog.items, ['local-a']);

      gate.complete();
      await pending;

      expect(catalog.loadState, EditorialCatalogLoadState.readyRemote);
      expect(catalog.items, ['remote-a']);
    });

    test('fromSources délègue aux contrats local et distant', () async {
      final catalog = ResilientEditorialCatalog<String>.fromSources(
        local: const _StubLocalCatalog(['local-a']),
        remote: const _StubRemoteCatalog(['remote-a']),
      );

      await catalog.warmUp();

      expect(catalog.loadState, EditorialCatalogLoadState.readyRemote);
      expect(catalog.items, ['remote-a']);
    });
  });
}

class _StubLocalCatalog implements EditorialLocalCatalog<String> {
  const _StubLocalCatalog(this.items);

  @override
  final List<String> items;
}

class _StubRemoteCatalog implements EditorialRemoteCatalog<String> {
  const _StubRemoteCatalog(this._items);

  final List<String> _items;

  @override
  Future<List<String>> fetchAll() async => _items;
}
