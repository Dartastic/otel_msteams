// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_msteams/otel_msteams.dart';

/// Traces Microsoft Graph calls with OpenTelemetry.
///
/// `otel_msteams` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Microsoft Graph call in
/// [tracedMsTeams]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'msteams-example');

  // Wraps a Microsoft Graph call related to Teams in a CLIENT span.
  final msTeamsId = await tracedMsTeams<String>(
    path: '/v1/orders',
    teamId: 'team_8f3a2c',
    channelId: 'channel_8f3a2c',
    messageId: 'message_8f3a2c',
    invoke: () async {
      // Make the Microsoft Graph call here, then report what it returned.
      return 'msteams_8f3a2c';
    },
  );
  OTelLog.info(
      'tracedMsTeams teams.channels.messages.create returned $msTeamsId');

  // Wraps a Microsoft Teams Incoming Webhook POST in a PRODUCER span.
  final msTeamsWebhookId = await tracedMsTeamsWebhook<String>(
    payloadSize: 512,
    card: 'example',
    invoke: () async {
      // Make the Microsoft Graph call here, then report what it returned.
      return 'msteams_8f3a2c';
    },
  );
  OTelLog.info('tracedMsTeamsWebhook returned $msTeamsWebhookId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMsteamsInstrumentationAsync.
  await runWithoutMsteamsInstrumentationAsync(
    () => tracedMsTeams<String>(
      path: '/v1/orders',
      teamId: 'team_8f3a2c',
      channelId: 'channel_8f3a2c',
      messageId: 'message_8f3a2c',
      invoke: () async {
        return 'msteams_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
