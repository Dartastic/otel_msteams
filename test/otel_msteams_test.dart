// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_msteams/otel_msteams.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_msteams-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Graph call records CLIENT span', () async {
    await tracedMsTeams<String>(
      path: 'teams.channels.messages.create',
      teamId: 't-1',
      channelId: 'c-1',
      invoke: () async => 'msg-1',
    );
    final a = attrsOf(
      spans.findSpanByName('msteams teams.channels.messages.create')!,
    );
    expect(a['msteams.path'], 'teams.channels.messages.create');
    expect(a['rpc.system'], 'microsoft-graph');
    expect(a['msteams.team.id'], 't-1');
    expect(a['msteams.channel.id'], 'c-1');
  });

  test('webhook records PRODUCER span', () async {
    await tracedMsTeamsWebhook<String>(
      payloadSize: 500,
      card: 'AdaptiveCard',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('msteams webhook');
    expect(span!.kind, SpanKind.producer);
    expect(attrsOf(span)['msteams.card.type'], 'AdaptiveCard');
  });

  test('suppression skips spans', () async {
    await runWithoutMsteamsInstrumentationAsync(() async {
      await tracedMsTeams<String>(
        path: 'teams.list',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('msteams '), isEmpty);
  });
}
