import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Play release configuration, so a refactor can't quietly ship an
/// unsigned, over-permissioned or wrongly-identified build.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('identity', () {
    test('applicationId and namespace agree and are the published id', () {
      expect(gradle,
          contains('applicationId = "br.com.bibliatraditio.biblia_traditio"'));
      expect(gradle,
          contains('namespace = "br.com.bibliatraditio.biblia_traditio"'));
    });

    test('the launcher label is the app name', () {
      expect(manifest, contains('android:label="Biblia Traditio"'));
    });

    test('the launcher icon points at the generated mipmap', () {
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    });

    test('the template TODOs are gone', () {
      expect(gradle, isNot(contains('TODO: Specify your own unique')));
      expect(gradle, isNot(contains('TODO: Add your own signing config')));
    });
  });

  group('sdk levels', () {
    test('targetSdk meets the Play Console requirement and is pinned', () {
      final m = RegExp(r'targetSdk = (\d+)').firstMatch(gradle);
      expect(m, isNotNull, reason: 'targetSdk must be pinned, not inherited');
      expect(int.parse(m!.group(1)!), greaterThanOrEqualTo(35));
    });

    test('minSdk is pinned at or above what the SQLite plugin needs', () {
      final m = RegExp(r'minSdk = (\d+)').firstMatch(gradle);
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), greaterThanOrEqualTo(21));
    });

    test('compileSdk is pinned', () {
      expect(RegExp(r'compileSdk = \d+').hasMatch(gradle), isTrue);
    });
  });

  group('signing', () {
    test('a release signing config exists and is wired to the release build',
        () {
      expect(gradle, contains('signingConfigs {'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
    });

    test('credentials come from key.properties or the environment', () {
      expect(gradle, contains('key.properties'));
      for (final env in [
        'BT_STORE_FILE',
        'BT_STORE_PASSWORD',
        'BT_KEY_ALIAS',
        'BT_KEY_PASSWORD',
      ]) {
        expect(gradle, contains(env), reason: env);
      }
    });

    test('no secret is hardcoded in the build script', () {
      expect(RegExp(r'(storePassword|keyPassword)\s*=\s*"').hasMatch(gradle),
          isFalse);
    });

    test('secrets and keystores are gitignored', () {
      final ignore = File('android/.gitignore').readAsStringSync();
      expect(ignore, contains('key.properties'));
      expect(ignore, contains('*.jks'));
      expect(ignore, contains('*.keystore'));
    });

    test('a filled-in key.properties is never committed', () {
      expect(File('android/key.properties').existsSync(), isFalse,
          reason: 'a real key.properties must stay out of the repo');
      // The template that documents the setup is committed instead.
      expect(File('android/key.properties.example').existsSync(), isTrue);
    });
  });

  group('privacy surface', () {
    test('the release manifest requests no permissions at all', () {
      // The app is fully offline; Data Safety declares no data collection and
      // no network. Debug/profile manifests add INTERNET for tooling only.
      expect(manifest.contains('uses-permission'), isFalse);
    });

    test('the debug-only INTERNET permission stays out of the release', () {
      final debug =
          File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
      expect(debug, contains('android.permission.INTERNET'));
    });

    test('the published privacy and support pages exist in the repo', () {
      expect(File('docs/privacy.html').existsSync(), isTrue);
      expect(File('docs/support.html').existsSync(), isTrue);
    });
  });

  group('versioning', () {
    test('version name and code come from pubspec', () {
      expect(gradle, contains('versionCode = flutter.versionCode'));
      expect(gradle, contains('versionName = flutter.versionName'));
    });

    test('pubspec carries a name+build version Play can accept', () {
      final m = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
              multiLine: true)
          .firstMatch(pubspec);
      expect(m, isNotNull, reason: 'version must be x.y.z+build');
      expect(int.parse(m!.group(4)!), greaterThanOrEqualTo(1));
    });
  });

  group('launcher assets', () {
    test('the adaptive icon and its densities were generated', () {
      expect(
          File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
              .existsSync(),
          isTrue);
      for (final d in ['hdpi', 'mdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(File('android/app/src/main/res/mipmap-$d/ic_launcher.png')
            .existsSync(), isTrue,
            reason: 'mipmap-$d');
      }
    });

    test('the native splash was generated, including the Android 12 variant',
        () {
      expect(
          File('android/app/src/main/res/drawable/launch_background.xml')
              .existsSync(),
          isTrue);
      expect(
          File('android/app/src/main/res/values-v31/styles.xml').existsSync(),
          isTrue);
    });
  });
}
