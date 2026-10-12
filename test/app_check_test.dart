import 'package:battleplan/app/app_check.dart';
import 'package:battleplan/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

// Which App Check provider each build uses (ARCH §6.9).
void main() {
  const dev = AppEnv(flavor: AppFlavor.dev, useEmulators: false);
  const prod = AppEnv(flavor: AppFlavor.prod, useEmulators: false);
  const emulators = AppEnv(flavor: AppFlavor.dev, useEmulators: true);

  AppCheckPlan plan(
    AppEnv env, {
    bool web = false,
    String key = '',
    String token = '',
  }) => planAppCheck(env: env, isWeb: web, webSiteKey: key, debugToken: token);

  test('is off on the emulators, even with a token or key', () {
    expect(plan(emulators).mode, AppCheckMode.off);
    expect(plan(emulators, token: 't', key: 'k').mode, AppCheckMode.off);
    expect(plan(emulators, web: true, key: 'k').mode, AppCheckMode.off);
  });

  test('dev phones use the debug provider, with a token when given', () {
    expect(plan(dev).mode, AppCheckMode.debug);
    expect(plan(dev).debugToken, isEmpty);
    expect(plan(dev, token: 'ci-token').debugToken, 'ci-token');
  });

  test('prod phones attest and never take a debug token', () {
    final p = plan(prod, token: 'leaked');
    expect(p.mode, AppCheckMode.attested);
    expect(p.debugToken, isEmpty);
  });

  test('web uses reCAPTCHA Enterprise with the site key', () {
    final p = plan(prod, web: true, key: 'site-key');
    expect(p.mode, AppCheckMode.attested);
    expect(p.webSiteKey, 'site-key');
    expect(plan(dev, web: true, key: 'site-key').mode, AppCheckMode.attested);
  });

  test('web without a site key is off rather than broken', () {
    expect(plan(prod, web: true).mode, AppCheckMode.off);
    expect(plan(dev, web: true).mode, AppCheckMode.off);
    expect(plan(prod, web: true, token: 't').mode, AppCheckMode.off);
  });

  test('a dev web build takes a debug token over the site key', () {
    final p = plan(dev, web: true, key: 'site-key', token: 'ci-token');
    expect(p.mode, AppCheckMode.debug);
    expect(p.debugToken, 'ci-token');
  });

  test('an off plan returns without touching Firebase', () async {
    await activateAppCheck(
      const AppCheckPlan(mode: AppCheckMode.off, reason: 'test'),
    );
  });
}
