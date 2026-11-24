import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cinebook_frontend/main.dart';
import 'package:cinebook_frontend/services/theme_controller.dart';
import 'package:cinebook_frontend/widgets/auth_dialog.dart';
import 'package:cinebook_frontend/widgets/reference_card.dart';
import 'package:cinebook_frontend/widgets/recommendation_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

final movies = [
  {
    'id': 1,
    'title': 'Premier film',
    'year': 2020,
    'vote_average': 8.0,
    'vote_count': 100,
    'pacing': 0.5,
    'genres': ['Drama'],
    'atmosphere_tags': [],
  },
  {
    'id': 2,
    'title': 'Deuxième film',
    'year': 2021,
    'vote_average': 7.0,
    'vote_count': 100,
    'pacing': 0.5,
    'genres': ['Action'],
    'atmosphere_tags': [],
  },
];

http.Response jsonResponse(Object data, [int code = 200]) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response respond(http.Request request) {
  if (request.url.path.endsWith('/genres')) {
    return jsonResponse([
      {'name': 'Drama'},
      {'name': 'Action'},
    ]);
  }
  if (request.url.path.endsWith('/movies')) {
    final query = request.url.queryParameters['query'];
    if (query == 'absent') return jsonResponse([]);
    if (query == 'erreur') return jsonResponse({'detail': 'offline'}, 503);
    final genre = request.url.queryParameters['genre'];
    return jsonResponse(
      genre == null
          ? movies
          : movies.where((m) => (m['genres'] as List).contains(genre)).toList(),
    );
  }
  if (request.url.path.endsWith('/recommend')) {
    final ids = (jsonDecode(request.body) as Map)['movie_ids'] as List;
    return jsonResponse({
      'reference_movie': movies.firstWhere((m) => m['id'] == ids.first),
      'reference_movies': movies.where((m) => ids.contains(m['id'])).toList(),
      'recommendations': [
        {
          ...movies.first,
          'id': 3,
          'title': 'Film découvert',
          'score': 0.8,
          'base_similarity': 0.8,
          'discovery_factor': 1.0,
          'sub_scores': {'Ambiance': 0.8},
          'explanation': 'Une ambiance proche.',
        },
      ],
    });
  }
  if (request.url.path.endsWith('/auth/login') ||
      request.url.path.endsWith('/auth/register')) {
    return jsonResponse({
      'access_token': 'test-token',
      'user': {'id': 1, 'email': 'ux@example.test'},
    }, request.url.path.endsWith('register') ? 201 : 200);
  }
  if (request.url.path.endsWith('/watchlist')) return jsonResponse([]);
  throw StateError('Unexpected request: ${request.method} ${request.url}');
}

void viewport(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.3);
  await frames(tester);
  await tester.tap(target);
  await frames(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferences.resetStatic();
  });

  for (final width in [360.0, 390.0, 768.0, 960.0, 1440.0]) {
    testWidgets(
      'Guest discovery, sticky search and optional settings at $width',
      (tester) async {
        viewport(tester, width);
        final requests = <http.Request>[];
        await http.runWithClient(
          () async {
            await tester.pumpWidget(const CineBookApp());
            await frames(tester);
            expect(find.text('DÉCOUVRIR SANS COMPTE'), findsOneWidget);
            expect(
              find.textContaining('TON CINÉMA.', findRichText: true),
              findsNothing,
            );
            expect(find.byType(AuthDialog), findsNothing);
            expect(find.byType(ReferenceCard), findsNothing);
            expect(
              requests.where((r) => r.url.path.endsWith('/recommend')),
              isEmpty,
            );
            final cta = tester.widget<ElevatedButton>(
              find.ancestor(
                of: find.text('CHOISIS UN FILM POUR COMMENCER'),
                matching: find.byWidgetPredicate(
                  (widget) => widget is ElevatedButton,
                ),
              ),
            );
            expect(cta.onPressed, isNull);
            expect(find.byType(Slider), findsNothing);
            final searchY = tester.getTopLeft(find.byType(TextField)).dy;
            await tapVisible(
              tester,
              find.widgetWithText(ActionChip, 'Premier film'),
            );
            expect(find.byType(AuthDialog), findsNothing);
            expect(
              requests.where((r) => r.url.path.endsWith('/recommend')).length,
              1,
            );
            await tapVisible(tester, find.text('VOIR MA SÉLECTION'));
            expect(tester.getTopLeft(find.byType(TextField)).dy, searchY);
            expect(find.byType(RecommendationCard), findsOneWidget);
            expect(find.text('Film découvert').hitTestable(), findsOneWidget);
            await tester.tap(
              width < 600 ? find.byTooltip('Watchlist') : find.text('Watchlist'),
            );
            await frames(tester);
            expect(find.text('Garde tes films pour plus tard'), findsOneWidget);
            expect(find.byType(AuthDialog), findsNothing);
            await tester.tap(find.text('Continuer sans compte'));
            await frames(tester);
            expect(
              requests.where((r) => r.url.path.contains('/auth/')),
              isEmpty,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
          () => MockClient((request) async {
            requests.add(request);
            return respond(request);
          }),
        );
      },
    );
  }

  testWidgets(
    'Header search shows empty and failure states and supports keyboard selection',
    (tester) async {
      viewport(tester, 390);
      await http.runWithClient(() async {
        await tester.pumpWidget(const CineBookApp());
        await frames(tester);
        final field = find.byType(TextField);
        await tester.enterText(field, 'absent');
        await frames(tester);
        expect(
          find.text('Aucun film trouvé. Essaie un autre titre.'),
          findsOneWidget,
        );
        await tester.enterText(field, 'erreur');
        await frames(tester);
        expect(find.text('Réessayer la recherche'), findsOneWidget);
        await tester.enterText(field, 'film');
        await frames(tester);
        expect(
          find.textContaining('Ajouter comme référence'),
          findsNWidgets(2),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await frames(tester);
        expect(find.textContaining('Ajouter comme référence'), findsNothing);
        expect(find.byType(ReferenceCard), findsOneWidget);
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(find.byType(AuthDialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((r) async => respond(r)));
    },
  );

  testWidgets(
    'Mobile keyboard submits search and recommendation errors can be retried',
    (tester) async {
      viewport(tester, 360, 800);
      var failRecommendation = true;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const CineBookApp());
          await frames(tester);
          tester.view.viewInsets = const FakeViewPadding(bottom: 350);
          addTearDown(tester.view.resetViewInsets);
          await tester.enterText(find.byType(TextField), 'film');
          await frames(tester);
          expect(
            find.textContaining('Ajouter comme référence'),
            findsNWidgets(2),
          );
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await frames(tester);
          tester.view.resetViewInsets();
          await frames(tester);
          expect(find.byType(ReferenceCard), findsOneWidget);
          expect(find.text('RÉESSAYER'), findsOneWidget);
          failRecommendation = false;
          await tapVisible(tester, find.text('RÉESSAYER'));
          await frames(tester);
          expect(find.byType(RecommendationCard), findsOneWidget);
          expect(find.byType(AuthDialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient(
          (r) async => r.url.path.endsWith('/recommend') && failRecommendation
              ? jsonResponse({'detail': 'offline'}, 503)
              : respond(r),
        ),
      );
    },
  );

  testWidgets('Saving requires login and the saved film can be removed', (
    tester,
  ) async {
    viewport(tester, 390, 900);
    SharedPreferences.setMockInitialValues({
      ThemeController.preferenceKey: 'light',
    });
    SharedPreferences.resetStatic();
    final requests = <http.Request>[];
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const CineBookApp());
        await frames(tester);
        await tapVisible(
          tester,
          find.widgetWithText(ActionChip, 'Premier film'),
        );
        await tapVisible(tester, find.text('VOIR MA SÉLECTION'));
        await tapVisible(tester, find.byTooltip('Ajouter à la watchlist'));
        expect(find.byType(AuthDialog), findsOneWidget);
        expect(
          requests.where(
            (r) => r.method == 'POST' && r.url.path.endsWith('/watchlist'),
          ),
          isEmpty,
        );
        await tester.tap(find.text('Continuer sans compte'));
        await frames(tester);
        expect(find.byType(RecommendationCard), findsOneWidget);
        await tapVisible(tester, find.byTooltip('Ajouter à la watchlist'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Adresse Email'),
          'ux@example.test',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mot de passe (6 caractères min)'),
          'test-pass',
        );
        await tapVisible(tester, find.text('SE CONNECTER'));
        expect(find.byTooltip('Watchlist (1)'), findsOneWidget);
        final saved = requests.singleWhere(
          (r) => r.method == 'POST' && r.url.path.endsWith('/watchlist'),
        );
        expect(jsonDecode(saved.body)['movie_id'], 3);
        expect(saved.headers['authorization'], 'Bearer test-token');
        await tester.tap(find.byTooltip('Watchlist (1)'));
        await frames(tester);
        expect(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('Film découvert'),
          ),
          findsOneWidget,
        );
        await tapVisible(
          tester,
          find.descendant(
            of: find.byType(Drawer),
            matching: find.byTooltip('Retirer de la watchlist'),
          ),
        );
        expect(find.text('Votre Watchlist est vide'), findsOneWidget);
        expect(
          requests.any(
            (r) => r.method == 'DELETE' && r.url.path.endsWith('/watchlist/3'),
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((r) async {
        requests.add(r);
        if (r.method == 'POST' && r.url.path.endsWith('/watchlist')) {
          return jsonResponse({
            'id': 1,
            'movie_id': 3,
            'status': 'to_watch',
            'movie': {...movies.first, 'id': 3, 'title': 'Film découvert'},
          }, 201);
        }
        if (r.method == 'DELETE' && r.url.path.endsWith('/watchlist/3')) {
          return jsonResponse({'ok': true});
        }
        return respond(r);
      }),
    );
  });

  testWidgets('An old search cannot reopen suggestions after clear', (
    tester,
  ) async {
    viewport(tester, 1440);
    final delayed = Completer<http.Response>();
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const CineBookApp());
        await frames(tester);
        await tester.enterText(find.byType(TextField), 'lent');
        await frames(tester);
        await tester.tap(find.byTooltip('Effacer la recherche'));
        await frames(tester);
        delayed.complete(jsonResponse(movies));
        await frames(tester);
        expect(find.textContaining('Ajouter comme référence'), findsNothing);
        expect(find.text('Recherche en cours…'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient(
        (r) => r.url.queryParameters['query'] == 'lent'
            ? delayed.future
            : Future.value(respond(r)),
      ),
    );
  });

  testWidgets(
    'Mix, genres, streaming, optional settings and reset remain usable',
    (tester) async {
      viewport(tester, 1440, 1000);
      SharedPreferences.setMockInitialValues({
        ThemeController.preferenceKey: 'light',
      });
      SharedPreferences.resetStatic();
      final requests = <http.Request>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const CineBookApp());
          await frames(tester);
          await tapVisible(
            tester,
            find.widgetWithText(ActionChip, 'Premier film'),
          );
          await tapVisible(
            tester,
            find.widgetWithText(ActionChip, 'Deuxième film'),
          );
          expect(find.text('MIX DE 2 FILMS'), findsOneWidget);
          final payload =
              jsonDecode(
                    requests
                        .lastWhere((r) => r.url.path.endsWith('/recommend'))
                        .body,
                  )
                  as Map;
          expect(payload['movie_ids'], [1, 2]);
          await tapVisible(
            tester,
            find.text('Affiner ma sélection (facultatif)'),
          );
          expect(find.byType(Slider), findsNWidgets(6));
          await tapVisible(tester, find.text('3 films'));
          expect(find.text('APPLIQUER LES RÉGLAGES'), findsOneWidget);
          await tapVisible(tester, find.text('APPLIQUER LES RÉGLAGES'));
          expect(
            (jsonDecode(
                  requests
                      .lastWhere((r) => r.url.path.endsWith('/recommend'))
                      .body,
                )
                as Map)['top_n'],
            3,
          );
          await tapVisible(tester, find.text('Ambiance Pure'));
          tester.widget<Slider>(find.byType(Slider).last).onChanged!(0.8);
          await frames(tester);
          await tapVisible(
            tester,
            find.byTooltip('Réinitialiser les réglages'),
          );
          await tapVisible(tester, find.text('APPLIQUER LES RÉGLAGES'));
          final reset =
              jsonDecode(
                    requests
                        .lastWhere((r) => r.url.path.endsWith('/recommend'))
                        .body,
                  )
                  as Map;
          expect(reset['top_n'], 5);
          expect(reset['discovery_slider'], 0.3);
          expect(reset['weights'], {
            'atmosphere': 1.5,
            'visual': 1.2,
            'genre': 1.0,
            'era': 0.5,
            'pacing': 0.8,
          });
          await tapVisible(tester, find.text('Netflix'));
          expect(
            (jsonDecode(
                  requests
                      .lastWhere((r) => r.url.path.endsWith('/recommend'))
                      .body,
                )
                as Map)['provider'],
            'Netflix',
          );
          await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Tous'));
          expect(
            (jsonDecode(
                      requests
                          .lastWhere((r) => r.url.path.endsWith('/recommend'))
                          .body,
                    )
                    as Map)
                .containsKey('provider'),
            isFalse,
          );
          await tapVisible(
            tester,
            find.byType(DropdownButtonFormField<String>),
          );
          await tester.tap(find.text('Drama').last);
          await frames(tester);
          expect(
            requests.any((r) => r.url.queryParameters['genre'] == 'Drama'),
            isTrue,
          );
          expect(
            find.widgetWithText(ActionChip, 'Deuxième film'),
            findsNothing,
          );
          expect(find.text('MIX DE 2 FILMS'), findsOneWidget);
          await tapVisible(tester, find.text('Tout effacer'));
          expect(find.byType(ReferenceCard), findsNothing);
          expect(find.byType(RecommendationCard), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient((r) async {
          requests.add(r);
          return respond(r);
        }),
      );
    },
  );

  testWidgets('Clearing a selection invalidates an in-flight recommendation', (
    tester,
  ) async {
    viewport(tester, 1440);
    final delayed = Completer<http.Response>();
    http.Request? pending;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const CineBookApp());
        await frames(tester);
        await tapVisible(
          tester,
          find.widgetWithText(ActionChip, 'Premier film'),
        );
        await tapVisible(
          tester,
          find.byTooltip('Retirer ce film de référence'),
        );
        delayed.complete(respond(pending!));
        await frames(tester);
        expect(find.byType(RecommendationCard), findsNothing);
        expect(find.text('Tes découvertes apparaîtront ici'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((r) {
        if (r.url.path.endsWith('/recommend')) {
          pending = r;
          return delayed.future;
        }
        return Future.value(respond(r));
      }),
    );
  });

  testWidgets(
    'Login is optional, keeps the selection and reveals the personal hero',
    (tester) async {
      viewport(tester, 360, 800);
      await http.runWithClient(() async {
        await tester.pumpWidget(const CineBookApp());
        await frames(tester);
        await tapVisible(
          tester,
          find.widgetWithText(ActionChip, 'Premier film'),
        );
        await tester.tap(find.byTooltip('Connexion (facultative)'));
        await frames(tester);
        expect(find.text('Continuer sans compte'), findsOneWidget);
        await tester.tap(find.text('Continuer sans compte'));
        await frames(tester);
        expect(find.byType(ReferenceCard), findsOneWidget);
        await tester.tap(find.byTooltip('Connexion (facultative)'));
        await frames(tester);
        await tester.enterText(
          find.widgetWithText(TextField, 'Adresse Email'),
          'ux@example.test',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mot de passe (6 caractères min)'),
          'test-pass',
        );
        await tapVisible(tester, find.text('SE CONNECTER'));
        expect(find.byType(AuthDialog), findsNothing);
        expect(
          find.textContaining('TON CINÉMA.', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('DÉCOUVRIR SANS COMPTE'), findsNothing);
        expect(find.byType(ReferenceCard), findsOneWidget);
        await tester.tap(find.byTooltip('Watchlist (0)'));
        await frames(tester);
        expect(find.text('Votre Watchlist est vide'), findsOneWidget);
        await tester.tap(find.text('Se déconnecter'));
        await frames(tester);
        expect(find.text('DÉCOUVRIR SANS COMPTE'), findsOneWidget);
        expect(find.byType(ReferenceCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((r) async => respond(r)));
    },
  );
}
