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
      expect(day.rank, LiturgicalRank.solemnity);
    });

    test('Easter Sundays land correctly (computus)', () {
      for (final (y, m, d) in [
        (2024, 3, 31),
        (2025, 4, 20),
        (2026, 4, 5),
        (2027, 3, 28),
        (2030, 4, 21),
      ]) {
        expect(on(y, m, d).celebration,
            'Domingo de Páscoa da Ressurreição do Senhor',
            reason: '$y-$m-$d');
      }
    });

    test('Sunday cycle rotates A→B→C by liturgical year', () {
      expect(on(2026, 3, 1).sundayCycle, 'A'); // 2025-26
      expect(on(2027, 3, 1).sundayCycle, 'B'); // 2026-27
      expect(on(2028, 3, 1).sundayCycle, 'C'); // 2027-28
    });

    test('weekday cycle alternates I/II', () {
      expect(on(2026, 6, 10).weekdayCycle, 'II'); // lit. year 2025-26
      expect(on(2027, 6, 10).weekdayCycle, 'I'); // lit. year 2026-27
    });

    test('the active cycle follows Sundays/solemnities vs weekdays', () {
      expect(on(2026, 6, 12).activeCycle, 'A'); // Sacred Heart (solemnity)
      expect(on(2026, 6, 10).activeCycle, 'II'); // an ordinary Wednesday
    });

    test('seasons and colours', () {
      expect(on(2026, 1, 15).season, LiturgicalSeason.ordinary);
      expect(on(2026, 2, 18).season, LiturgicalSeason.lent); // Ash Wed 2026
      expect(on(2026, 2, 18).color, LiturgicalColor.purple);
      expect(on(2026, 5, 24).celebration, 'Domingo de Pentecostes');
      expect(on(2026, 5, 24).color, LiturgicalColor.red);
      expect(on(2026, 12, 6).season, LiturgicalSeason.advent);
      expect(on(2026, 12, 6).color, LiturgicalColor.purple);
      expect(on(2026, 12, 25).celebration, 'Natal do Senhor');
    });

    test('Gaudete & Laetare are rose', () {
      expect(on(2026, 12, 13).color, LiturgicalColor.rose); // Gaudete
      expect(on(2026, 3, 15).color, LiturgicalColor.rose); // Laetare
    });

    test('fixed solemnities', () {
      expect(on(2026, 8, 15).celebration, 'Assunção de Nossa Senhora');
      expect(on(2026, 11, 1).celebration, 'Todos os Santos');
      expect(on(2026, 12, 8).celebration,
          'Imaculada Conceição de Nossa Senhora');
    });
  });

  group('days that used to fall through to a generic name', () {
    test('Ash Wednesday is named, not "after the Ashes"', () {
      expect(on(2026, 2, 18).celebration, 'Quarta-feira de Cinzas');
      expect(on(2025, 3, 5).celebration, 'Quarta-feira de Cinzas');
    });

    test('the Thursday after Ash Wednesday still reads as a Lenten feria', () {
      expect(on(2026, 2, 19).celebration, 'Quinta-feira depois das Cinzas');
    });

    test('Holy Week weekdays are named', () {
      // Easter 2026 = 5 April; Palm Sunday = 29 March.
      expect(on(2026, 3, 30).celebration, 'Segunda-feira da Semana Santa');
      expect(on(2026, 4, 1).celebration, 'Quarta-feira da Semana Santa');
      expect(on(2026, 4, 2).celebration, 'Quinta-feira Santa');
      expect(on(2026, 4, 3).celebration, 'Sexta-feira Santa da Paixão do Senhor');
      expect(on(2026, 4, 4).celebration, 'Sábado Santo');
    });

    test('the Easter Octave days are solemnities, not ferias', () {
      final monday = on(2026, 4, 6);
      expect(monday.celebration, 'Segunda-feira da Oitava da Páscoa');
      expect(monday.rank, LiturgicalRank.solemnity);
      expect(monday.observance.isInOctave, isTrue);
      expect(on(2026, 4, 12).celebration,
          '2º Domingo da Páscoa (da Divina Misericórdia)');
    });

    test('the Christmas Octave is named day by day', () {
      // 2025: 26–27 December are Friday and Saturday, so the two feasts of the
      // Octave keep their days (in 2026 the 27th is the Sunday of Holy Family).
      expect(on(2025, 12, 26).celebration, 'Santo Estêvão, primeiro mártir');
      expect(on(2025, 12, 27).celebration, 'São João, apóstolo e evangelista');
      expect(on(2025, 12, 29).celebration, '5º dia da Oitava do Natal');
      expect(on(2026, 12, 28).celebration, 'Santos Inocentes, mártires');
      expect(on(2026, 12, 31).celebration, '7º dia da Oitava do Natal');
      expect(on(2026, 12, 31).observance.isInOctave, isTrue);
    });

    test('Holy Family and the Baptism of the Lord are feasts of the Lord', () {
      // The Sunday inside the Octave takes precedence over a saint's feast:
      // in 2026 the 27th is a Sunday, so Holy Family wins over St John.
      expect(on(2026, 12, 27).celebration,
          'Sagrada Família de Jesus, Maria e José');
      // 2025: Christmas Thursday → Holy Family Sunday 28 December.
      expect(on(2025, 12, 28).celebration,
          'Sagrada Família de Jesus, Maria e José');
      // 2022: Christmas fell on a Sunday → Holy Family kept on 30 December.
      expect(on(2022, 12, 30).celebration,
          'Sagrada Família de Jesus, Maria e José');
      final baptism = on(2026, 1, 11);
      expect(baptism.celebration, 'Batismo do Senhor');
      expect(baptism.rank, LiturgicalRank.feast);
      expect(baptism.season, LiturgicalSeason.christmas);
      // Ordinary Time resumes the next day.
      expect(on(2026, 1, 12).season, LiturgicalSeason.ordinary);
    });

    test('the Immaculate Heart follows the Sacred Heart', () {
      final day = on(2026, 6, 13);
      expect(day.celebration, 'Imaculado Coração de Maria');
      expect(day.rank, LiturgicalRank.memorial);
    });

    test('Christ the King closes the year', () {
      expect(on(2026, 11, 22).celebration,
          'Nosso Senhor Jesus Cristo, Rei do Universo');
    });
  });

  group('week of the season', () {
    test('Advent counts 1–4', () {
      expect(on(2026, 11, 29).week, 1); // 1st Sunday of Advent 2026
      expect(on(2026, 12, 20).week, 4);
    });

    test('Lent counts 1–6, and the days after Ash Wednesday have no week', () {
      expect(on(2026, 2, 19).week, isNull);
      expect(on(2026, 2, 22).week, 1); // 1st Sunday of Lent
      expect(on(2026, 3, 29).week, 6); // Palm Sunday week
    });

    test('Easter counts 1–8', () {
      expect(on(2026, 4, 5).week, 1);
      expect(on(2026, 5, 24).week, 8); // Pentecost
    });

    test('Ordinary Time runs 1–34 across both blocks', () {
      // First block: the Monday after the Baptism opens week 1.
      expect(on(2026, 1, 12).week, 1);
      expect(on(2026, 1, 18).week, 2); // 2nd Sunday of Ordinary Time
      // Second block ends at Christ the King = week 34.
      expect(on(2026, 11, 22).week, 34);
      expect(on(2026, 11, 15).week, 33);
      // …and resumes right after Pentecost without a gap.
      expect(on(2026, 5, 25).week, 8);
    });

    test('every Ordinary Time week stays within 1–34 for a decade', () {
      for (var y = 2024; y <= 2034; y++) {
        for (var d = DateTime(y, 1, 1);
            d.year == y;
            d = DateTime(d.year, d.month, d.day + 1)) {
          final day = cal.resolve(d);
          if (day.season != LiturgicalSeason.ordinary) continue;
          expect(day.week, isNotNull, reason: '$d');
          expect(day.week, inInclusiveRange(1, 34), reason: '$d');
        }
      }
    });
  });

  group('precedence', () {
    test('a solemnity outranks the Sunday of Ordinary Time it falls on', () {
      // 15 August 2027 is a Sunday.
      final day = on(2027, 8, 15);
      expect(day.celebration, 'Assunção de Nossa Senhora');
      expect(day.rank, LiturgicalRank.solemnity);
    });

    test('a feast of a saint yields to the Sunday it falls on', () {
      // 25 April 2027 (St Mark) is a Sunday of Easter.
      final day = on(2027, 4, 25);
      expect(day.celebration, contains('Domingo da Páscoa'));
    });

    test('a feast of the Lord outranks a Sunday of Ordinary Time', () {
      // 6 August 2028 (Transfiguration) is a Sunday.
      expect(on(2028, 8, 6).celebration, 'Transfiguração do Senhor');
    });

    test('a Lenten weekday outranks an obligatory memorial, which stays optional',
        () {
      // 7 March 2026 (Ss Perpetua & Felicity, memorial) is a Lenten Saturday.
      final day = on(2026, 3, 7);
      expect(day.season, LiturgicalSeason.lent);
      expect(day.rank, LiturgicalRank.weekday);
      expect(day.optionalMemorials.map((m) => m.name),
          contains('Santas Perpétua e Felicidade, mártires'));
    });

    test('an obligatory memorial wins an ordinary weekday', () {
      // 28 January 2026 (St Thomas Aquinas) is an ordinary Wednesday.
      final day = on(2026, 1, 28);
      expect(day.celebration, 'São Tomás de Aquino');
      expect(day.rank, LiturgicalRank.memorial);
    });

    test('optional memorials on an ordinary weekday are offered, not imposed',
        () {
      // 20 January 2026: Ss Fabian and Sebastian, both optional.
      final day = on(2026, 1, 20);
      expect(day.rank, LiturgicalRank.weekday);
      expect(day.optionalMemorials.map((m) => m.name),
          containsAll(['São Fabiano, papa e mártir', 'São Sebastião, mártir']));
    });
  });

  group('transferred celebrations', () {
    test('a solemnity inside the Easter Octave is not celebrated there (2008)',
        () {
      // Easter 2008 = 23 March, so both St Joseph (19 Mar, Holy Week) and the
      // Annunciation (25 Mar, Octave) were impeded. Neither may be kept on its
      // own date. Note the engine applies the general rule — postponement —
      // while the Holy See that year *anticipated* St Joseph to 15 March.
      expect(on(2008, 3, 25).celebration, isNot(contains('Anunciação')));
      expect(on(2008, 3, 19).celebration, isNot(contains('São José')));
    });

    test('the Annunciation moves out of Holy Week (2016)', () {
      // 25 March 2016 was Good Friday; the solemnity moved to 4 April.
      expect(on(2016, 3, 25).celebration, 'Sexta-feira Santa da Paixão do Senhor');
      expect(on(2016, 4, 4).celebration, 'Anunciação do Senhor');
    });

    test('two impeded solemnities do not land on the same day', () {
      // 2008: both St Joseph (19 Mar, Holy Week) and the Annunciation are
      // impeded. They must occupy different days.
      final joseph = <DateTime>[];
      for (var d = DateTime(2008, 3, 20); d.isBefore(DateTime(2008, 4, 15));
          d = DateTime(d.year, d.month, d.day + 1)) {
        final c = cal.resolve(d).celebration;
        if (c.contains('São José') || c.contains('Anunciação')) joseph.add(d);
      }
      expect(joseph.length, 2, reason: 'both solemnities must be placed');
      expect(joseph.toSet().length, 2, reason: 'and on distinct days');
    });

    test('an unimpeded solemnity stays on its own date', () {
      expect(on(2026, 3, 25).celebration, 'Anunciação do Senhor');
      expect(on(2026, 3, 19).celebration, 'São José, esposo da Virgem Maria');
    });
  });

  group('observances', () {
    test('Ash Wednesday and Good Friday are fast and abstinence', () {
      for (final day in [on(2026, 2, 18), on(2026, 4, 3)]) {
        expect(day.observance.isFastDay, isTrue);
        expect(day.observance.isAbstinenceDay, isTrue);
      }
    });

    test('Fridays carry abstinence unless a solemnity falls on them', () {
      expect(on(2026, 3, 6).observance.isAbstinenceDay, isTrue); // Lenten Friday
      // 25 December 2026 is a Friday and a solemnity.
      expect(on(2026, 12, 25).observance.isAbstinenceDay, isFalse);
    });

    test('Sundays and the universal holy days are days of obligation', () {
      expect(on(2026, 6, 14).observance.isHolyDayOfObligation, isTrue); // Sunday
      expect(on(2026, 8, 15).observance.isHolyDayOfObligation, isTrue);
      expect(on(2026, 1, 1).observance.isHolyDayOfObligation, isTrue);
      expect(on(2026, 6, 10).observance.isHolyDayOfObligation, isFalse);
    });
  });

  group('robustness', () {
    test('resolving every day of a decade never throws and always names a day',
        () {
      for (var y = 2020; y <= 2035; y++) {
        for (var d = DateTime(y, 1, 1);
            d.year == y;
            d = DateTime(d.year, d.month, d.day + 1)) {
          final day = cal.resolve(d);
          expect(day.celebration.trim(), isNotEmpty, reason: '$d');
          expect(day.date, DateTime(d.year, d.month, d.day));
        }
      }
    });

    test('a DateTime carrying a time component resolves to the same day', () {
      final withTime = cal.resolve(DateTime(2026, 4, 5, 23, 59, 59));
      expect(withTime.celebration, on(2026, 4, 5).celebration);
      expect(withTime.date, DateTime(2026, 4, 5));
    });
  });
}
