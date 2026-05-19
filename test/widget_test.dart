import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playgrid_mobile/app.dart';
import 'package:playgrid_mobile/features/auth/data/local_playgrid_repository.dart';
import 'package:playgrid_mobile/shared/models/playgrid_mock_data.dart';

void main() {
  testWidgets('shows the login surface when no Supabase credentials are set',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PlayGridClubApp()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('PlayGrid Club'), findsWidgets);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  test('local repository rejects overlapping bookings', () async {
    final LocalPlayGridRepository repository = LocalPlayGridRepository();
    final state =
        await repository.bootstrap(session: PlayGridMockData.memberSession);
    final sport = state.sports.first;

    await repository.createBooking(
      session: state.session,
      venueId: 'venue-ridge',
      sportId: sport.id,
      startAt: DateTime(2026, 5, 21, 20, 0),
      endAt: DateTime(2026, 5, 21, 21, 0),
      notes: 'Team practice',
    );

    expect(
      () => repository.createBooking(
        session: state.session,
        venueId: 'venue-ridge',
        sportId: sport.id,
        startAt: DateTime(2026, 5, 21, 20, 30),
        endAt: DateTime(2026, 5, 21, 21, 30),
        notes: 'Conflicting slot',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
