import 'package:biblia_traditio/features/liturgy/domain/liturgical_calendar.dart';
import 'package:biblia_traditio/features/liturgy/domain/liturgical_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cal = LiturgicalCalendar();

  LiturgicalDay on(int y, int m, int d) => cal.resolve(DateTime(y, m, d));

  group('temporal cycle', () {
    test('the screenshot day: 12 Jun 2026 = Sacred Heart, Tempo Comum, Ano A',
        () {
      final day = on(2026, 6, 12);
      expect(day.celebration, 'Sagrado Coração de Jesus');
      expect(day.season, LiturgicalSeason.ordinary);
      expect(day.color, LiturgicalColor.white);
      expect(day.sundayCycle, 'A');
    });

    test('Easter Sundays land correctly (computus)', () {
      expect(on(2024, 3, 31).celebration, 'Domingo de Páscoa');
      expect(on(2025, 4, 20).celebration, 'Domingo de Páscoa');
      expect(on(2026, 4, 5).celebration, 'Domingo de Páscoa');
      expect(on(2027, 3, 28).celebration, 'Domingo de Páscoa');
    });

    test('Sunday cycle rotates A→B→C by liturgical year', () {
      // Each Lent (after Advent start) reflects its liturgical year's cycle.
      expect(on(2026, 3, 1).sundayCycle, 'A'); // 2025-26
      expect(on(2027, 3, 1).sundayCycle, 'B'); // 2026-27
      expect(on(2028, 3, 1).sundayCycle, 'C'); // 2027-28
    });

    test('weekday cycle alternates I/II', () {
      expect(on(2026, 6, 10).weekdayCycle, 'II'); // lit. year 2025-26
      expect(on(2027, 6, 10).weekdayCycle, 'I'); // lit. year 2026-27
    });

    test('seasons and colours', () {
      expect(on(2026, 1, 15).season, LiturgicalSeason.ordinary); // after Baptism
      expect(on(2026, 2, 18).season, LiturgicalSeason.lent); // Ash Wed 2026
      expect(on(2026, 2, 18).color, LiturgicalColor.purple);
      expect(on(2026, 5, 24).celebration, 'Pentecostes');
      expect(on(2026, 5, 24).color, LiturgicalColor.red);
      expect(on(2026, 12, 6).season, LiturgicalSeason.advent);
      expect(on(2026, 12, 6).color, LiturgicalColor.purple);
      expect(on(2026, 12, 25).celebration, 'Natal do Senhor');
    });

    test('Gaudete & Laetare are rose', () {
      // 3rd Sunday of Advent 2026 and 4th Sunday of Lent 2026.
      expect(on(2026, 12, 13).color, LiturgicalColor.rose); // Gaudete
      expect(on(2026, 3, 15).color, LiturgicalColor.rose); // Laetare
    });

    test('fixed solemnities', () {
      expect(on(2026, 8, 15).celebration, 'Assunção de Nossa Senhora');
      expect(on(2026, 11, 1).celebration, 'Todos os Santos');
      expect(on(2026, 12, 8).celebration, 'Imaculada Conceição');
    });
  });
}
