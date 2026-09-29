import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalapulse/core/localization/strings.dart';
import 'package:qalapulse/core/theme/app_theme.dart';
import 'package:qalapulse/features/create_incident/create_screen.dart';
import 'package:qalapulse/shared/widgets/async_panel.dart';
import 'package:qalapulse/shared/widgets/persisted_text_field.dart';
import 'support.dart';

Widget localized(Widget child, {String language = 'ru'}) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'external transcription updates the editable text without losing manual changes',
    (tester) async {
      var text = 'Исходное описание';
      late StateSetter refresh;
      await tester.pumpWidget(
        localized(
          StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return PersistedTextField(
                value: text,
                label: 'Описание',
                onChanged: (value) => setState(() => text = value),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Мой текст');
      expect(text, 'Мой текст');
      refresh(() => text = 'Проверенный транскрипт');
      await tester.pump();
      expect(find.text('Проверенный транскрипт'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Исправленный транскрипт');
      expect(text, 'Исправленный транскрипт');
    },
  );
  testWidgets(
    'loading, retry after error, and successful content are visible',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        localized(
          AsyncPanel<String>(
            value: const AsyncLoading(),
            builder: Text.new,
            onRetry: () {},
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(
        localized(
          AsyncPanel<String>(
            value: AsyncError(StateError('failure'), StackTrace.current),
            builder: Text.new,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.tap(find.text('Повторить'));
      expect(retried, isTrue);
      await tester.pumpWidget(
        localized(
          AsyncPanel<String>(
            value: const AsyncData('Успех'),
            builder: Text.new,
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Успех'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
  testWidgets(
    'AI result exposes mock limitations and non-civic warning in both languages',
    (tester) async {
      final analysis = {
        'mode': 'mock',
        'result': {
          'is_civic_issue': false,
          'confidence': 0.0,
          'explanation_ru': 'Демо пояснение',
          'explanation_kk': 'Сынақ түсіндірмесі',
        },
      };
      await tester.pumpWidget(localized(AiResultNotice(analysis: analysis)));
      expect(find.textContaining('фотография не распознаётся'), findsOneWidget);
      expect(
        find.textContaining('может не быть городской проблемы'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        localized(AiResultNotice(analysis: analysis), language: 'kk'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Сынақ түсіндірмесі'), findsOneWidget);
      expect(find.textContaining('сурет танылмайды'), findsOneWidget);
    },
  );
  testWidgets('duplicate cards require an explicit confirmation action', (
    tester,
  ) async {
    String? confirmed;
    await tester.pumpWidget(
      localized(
        DuplicateCards(
          candidates: [
            {'incident': sampleIncident().toJson(), 'similarity_score': 0.9},
          ],
          onConfirm: (id) => confirmed = id,
        ),
      ),
    );
    expect(find.text('Яма на дороге'), findsOneWidget);
    expect(confirmed, isNull);
    await tester.tap(find.text('Подтвердить эту проблему'));
    expect(confirmed, 'incident-1');
  });
}
