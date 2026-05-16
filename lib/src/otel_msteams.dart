// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_msteams_suppression.dart';

const _tracerName = 'dartastic_otel_libs_msteams';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Microsoft Graph call related to Teams in a CLIENT span.
/// [path] is the Graph endpoint segment (e.g.
/// `teams.channels.messages.create`).
Future<T> tracedMsTeams<T>({
  required String path,
  required Future<T> Function() invoke,
  String? teamId,
  String? channelId,
  String? messageId,
}) async {
  if (msteamsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'msteams.path': path,
    'msteams.operation': path,
    'rpc.system': 'microsoft-graph',
  };
  if (teamId != null) m['msteams.team.id'] = teamId;
  if (channelId != null) m['msteams.channel.id'] = channelId;
  if (messageId != null) m['msteams.message.id'] = messageId;

  final span = _tracer().startSpan(
    'msteams $path',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Microsoft Teams Incoming Webhook POST in a PRODUCER span.
Future<T> tracedMsTeamsWebhook<T>({
  required Future<T> Function() invoke,
  int? payloadSize,
  String? card,
}) async {
  if (msteamsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'msteams_webhook',
    'messaging.operation': 'publish',
    'messaging.destination.name': 'msteams_webhook',
  };
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;
  if (card != null) m['msteams.card.type'] = card;

  final span = _tracer().startSpan(
    'msteams webhook',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
