import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_screen.dart';
import 'package:qalapulse/features/create_incident/create_screen.dart';
import 'package:qalapulse/features/create_incident/draft_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'support.dart';
import 'widgets_test.dart' show localized;

void main() {
  testWidgets(
    'partially restored coordinates remain editable without a null crash',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await DraftStore(prefs, testUser.id).save(
        const IncidentDraft(
          key: 'partial-location',
          step: 1,
          latitude: 43.2389,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            tokenStoreProvider.overrideWithValue(
              MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
            ),
          ],
          child: localized(const SizedBox(height: 900, child: CreateScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final longitude = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Долгота',
      );
      await tester.ensureVisible(longitude);
      await tester.enterText(longitude, '76.8897');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final restored = DraftStore(prefs, testUser.id).load()!;
      expect(restored.latitude, 43.2389);
      expect(restored.longitude, 76.8897);
    },
  );
  testWidgets('AI title can be corrected and restored from the draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await DraftStore(prefs, testUser.id).save(
      const IncidentDraft(
        key: 'review-key',
        step: 4,
        title: 'Предложение AI',
        description: 'Описание',
        categoryId: 'other',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(
            MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
          ),
          categoriesProvider.overrideWith(
            (ref) async => [
              const IncidentCategory(
                id: 'other',
                code: 'other',
                nameRu: 'Другое',
                nameKk: 'Басқа',
                description: '',
                baseSeverity: 3,
                icon: 'other',
                color: '#087E70',
              ),
            ],
          ),
        ],
        child: localized(const SizedBox(height: 900, child: CreateScreen())),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Заголовок',
    );
    await tester.enterText(title, 'Исправленный заголовок');
    await tester.pumpAndSettle();
    expect(
      DraftStore(prefs, testUser.id).load()!.title,
      'Исправленный заголовок',
    );
    expect(DraftStore(prefs, testUser.id).load()!.reviewed, isFalse);
  });

  testWidgets(
    'switching login to registration never moves password into another field',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tokenStoreProvider.overrideWithValue(MemoryTokens())],
          child: localized(const SizedBox(height: 900, child: AuthScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'person@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'Private-password!',
      );
      await tester.ensureVisible(find.text('Создать аккаунт'));
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();
      final email = tester.widget<TextFormField>(
        find.byKey(const ValueKey('auth-email')),
      );
      final password = tester.widget<TextFormField>(
        find.byKey(const ValueKey('auth-password')),
      );
      final name = tester.widget<TextFormField>(
        find.byKey(const ValueKey('auth-name')),
      );
      expect(email.controller!.text, 'person@example.com');
      expect(password.controller!.text, 'Private-password!');
      expect(name.controller!.text, isEmpty);
    },
  );
}
