import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onion_guard/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageProvider.t fallback chain', () {
    test('Kusaal (ku) falls back to Dagbani (dg) when no native entry exists', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('ku');

      expect(provider.t('home'), 'Yili');
      expect(provider.t('freshness'), 'Palli');
      expect(provider.t('analytics'), 'Yɛltɔɣa');
    });

    test('Gurene (gu) falls back to Dagbani (dg) when no native entry exists', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('gu');

      expect(provider.t('home'), 'Yili');
      expect(provider.t('freshness'), 'Palli');
      expect(provider.t('analytics'), 'Yɛltɔɣa');
    });

    test('Existing languages still resolve to their own entries, not dg', () async {
      final provider = LanguageProvider();

      await provider.setLanguage('en');
      expect(provider.t('home'), 'Home');

      await provider.setLanguage('fr');
      expect(provider.t('home'), 'Accueil');

      await provider.setLanguage('tw');
      expect(provider.t('home'), 'Fie');

      await provider.setLanguage('ha');
      expect(provider.t('home'), 'Gida');

      await provider.setLanguage('dg');
      expect(provider.t('home'), 'Yili');
    });

    test('Unknown key returns the key itself', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('ku');
      expect(provider.t('this_key_does_not_exist'), 'this_key_does_not_exist');
    });

    test('ku/gu fallback applies to the strings just edited on the Talk To Us page', () async {
      final provider = LanguageProvider();

      await provider.setLanguage('ku');
      expect(provider.t('feedback_subject_hint'), 'App Crashes');
      expect(provider.t('feedback_message_hint'), 'Yɛli yɛla maa, sabbi adwene bee suggestion zaŋ ka');
      expect(provider.t('talk_to_us_intro_body'),
          'Yɛli ti sani gba a, sabbi yele palli, bee yɛli a tehigu OnionGuard zuɣu.');

      await provider.setLanguage('gu');
      expect(provider.t('feedback_subject_hint'), 'App Crashes');
      expect(provider.t('feedback_message_hint'), 'Yɛli yɛla maa, sabbi adwene bee suggestion zaŋ ka');
    });

    test('Admin analytics keys translate across all languages', () async {
      final provider = LanguageProvider();
      const keys = [
        'platform_analytics',
        'users',
        'scans',
        'healthy',
        'diseased',
        'no_analytics_data',
      ];
      const codes = ['en', 'tw', 'dg', 'ee', 'ha', 'mp', 'fr', 'ku', 'gu'];
      for (final code in codes) {
        await provider.setLanguage(code);
        for (final key in keys) {
          final value = provider.t(key);
          expect(value, isNot(equals(key)),
              reason: 'Missing translation for $key in $code');
          expect(value, isNotEmpty,
              reason: 'Empty translation for $key in $code');
        }
      }
    });

    test('Admin analytics English values match what the page expects', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('en');
      expect(provider.t('platform_analytics'), 'Platform Analytics');
      expect(provider.t('users'), 'Users');
      expect(provider.t('scans'), 'Scans');
      expect(provider.t('healthy'), 'Healthy');
      expect(provider.t('diseased'), 'Diseased');
      expect(provider.t('no_analytics_data'), 'No analytics data yet');
    });

    test('Admin analytics ku/gu fall back to Dagbani for the new keys', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('ku');
      expect(provider.t('platform_analytics'), 'Platform Yɛltɔɣa');
      expect(provider.t('users'), 'Niriba');
      expect(provider.t('healthy'), 'Alaafee');
      await provider.setLanguage('gu');
      expect(provider.t('diseased'), 'Doroyaa');
      expect(provider.t('scans'), 'Daliri');
    });

    test('User analytics page keys translate across all languages', () async {
      final provider = LanguageProvider();
      const keys = [
        'your_farm_analytics',
        'farm_analytics_subtitle',
        'total_scans',
        'start_scanning_hint',
        'scans_over_time',
        'scans_over_time_subtitle',
        'chart_tooltip_breakdown',
        'disease_distribution',
        'disease_distribution_subtitle',
        'no_data',
        'weekly_pattern',
        'you_scan_most_on',
        'activity_by_day_of_week',
        'recent_scans',
        'recent_scans_subtitle_one',
        'recent_scans_subtitle_many',
        'no_recent_activity',
        'just_now',
        'minutes_ago',
        'hours_ago',
        'days_ago',
        'confidence_dot',
        'weekday_mon_short',
        'weekday_tue_short',
        'weekday_wed_short',
        'weekday_thu_short',
        'weekday_fri_short',
        'weekday_sat_short',
        'weekday_sun_short',
      ];
      const codes = ['en', 'tw', 'dg', 'ee', 'ha', 'mp', 'fr', 'ku', 'gu'];
      for (final code in codes) {
        await provider.setLanguage(code);
        for (final key in keys) {
          final value = provider.t(key);
          expect(value, isNot(equals(key)),
              reason: 'Missing translation for $key in $code');
          expect(value, isNotEmpty,
              reason: 'Empty translation for $key in $code');
        }
      }
    });

    test('tf substitutes {placeholder} tokens', () async {
      final provider = LanguageProvider();

      await provider.setLanguage('en');
      expect(provider.tf('scans_over_time_subtitle', {'days': 7}),
          'Last 7 days · green = healthy · orange = diseased');
      expect(provider.tf('chart_tooltip_breakdown', {'healthy': 5, 'diseased': 2}),
          '5 healthy · 2 diseased');
      expect(provider.tf('you_scan_most_on', {'day': 'Mon'}), 'You scan most on Mon');
      expect(provider.tf('minutes_ago', {'n': 12}), '12m ago');
      expect(provider.tf('hours_ago', {'n': 3}), '3h ago');
      expect(provider.tf('days_ago', {'n': 4}), '4d ago');
      expect(provider.tf('confidence_dot', {'pct': '92.5'}), '92.5% confidence');
      expect(provider.tf('recent_scans_subtitle_one', {'count': 1}), 'Your last 1 scan');
      expect(provider.tf('recent_scans_subtitle_many', {'count': 8}), 'Your last 8 scans');
    });

    test('tf works in non-English languages', () async {
      final provider = LanguageProvider();

      await provider.setLanguage('fr');
      expect(provider.tf('scans_over_time_subtitle', {'days': 30}),
          'Derniers 30 jours · vert = sain · orange = malade');
      expect(provider.tf('minutes_ago', {'n': 5}), 'Il y a 5 min');

      await provider.setLanguage('ku');
      // ku falls back to dg
      expect(provider.tf('minutes_ago', {'n': 5}), 'Manti 5 din gariga');
    });

    test('tf leaves the placeholder text identical when no params given', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('en');
      expect(provider.tf('scans_over_time_subtitle', const {}),
          'Last {days} days · green = healthy · orange = diseased');
    });
  });
}
