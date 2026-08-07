import 'liturgical_day.dart';

/// One explained topic in the directory: a short title and a few pastoral
/// paragraphs.
class DirectoryTopic {
  final String title;
  final List<String> paragraphs;
  const DirectoryTopic(this.title, this.paragraphs);
}

/// Everything the directory can say about a given day.
class DirectoryEntry {
  /// Why the season exists and what it asks of the reader.
  final DirectoryTopic season;

  /// The particular celebration, when it is one the directory knows.
  final DirectoryTopic? celebration;

  /// What today's liturgical colour means.
  final DirectoryTopic color;

  /// What this grade of celebration means (solemnity, feast, memorial…).
  final DirectoryTopic rank;

  /// Practical notes: obligation, fast, abstinence, octave, optional memorials.
  final List<String> practical;

  const DirectoryEntry({
    required this.season,
    required this.color,
    required this.rank,
    required this.practical,
    this.celebration,
  });
}

/// Explains the current celebration, offline and in Portuguese.
///
/// The content is a concise, original summary of what the Church's own books
/// say — the *Normas Universais sobre o Ano Litúrgico e o Calendário* (1969),
/// the *Instrução Geral do Missal Romano* and the Code of Canon Law for the
/// precept and penitential days. Nothing here is devotional invention: it
/// describes the liturgy as the Roman Rite orders it.
class LiturgicalDirectory {
  const LiturgicalDirectory();

  DirectoryEntry explain(LiturgicalDay day) => DirectoryEntry(
        season: _season(day),
        celebration: _celebration(day),
        color: _color(day.color),
        rank: _rank(day.rank),
        practical: _practical(day),
      );

  // ── Seasons ───────────────────────────────────────────────────────────────
  DirectoryTopic _season(LiturgicalDay day) => switch (day.season) {
        LiturgicalSeason.advent => const DirectoryTopic('Advento', [
            'O Advento abre o ano litúrgico. São quatro semanas de espera que olham em duas direções ao mesmo tempo: preparam o coração para o Natal, memória da primeira vinda de Cristo, e despertam a expectativa da sua vinda gloriosa no fim dos tempos.',
            'Por isso o tom é de vigilância alegre, não de penitência: a cor é roxa, mas o Advento não é uma segunda Quaresma. A partir de 17 de dezembro a liturgia muda de registo e volta-se inteiramente para o Natal que se aproxima.',
            'No terceiro domingo — o Domingo *Gaudete*, "Alegrai-vos" — as vestes podem ser rosa, sinal de que a espera já está próxima do seu termo.',
          ]),
        LiturgicalSeason.christmas => const DirectoryTopic('Tempo do Natal', [
            'O Tempo do Natal celebra a manifestação de Deus feito homem. Vai da Missa da noite de 25 de dezembro até ao Batismo do Senhor, e tem no meio a Epifania, quando o Salvador se dá a conhecer a todos os povos.',
            'Os oito primeiros dias formam a Oitava do Natal: cada um deles é celebrado com a solenidade do próprio dia de Natal, e nela entram a Sagrada Família, os primeiros mártires e, a 1 de janeiro, Santa Maria, Mãe de Deus.',
            'A cor é branca, cor da luz e da alegria. O tempo fecha-se com o Batismo do Senhor, que encerra a infância de Cristo e abre a sua vida pública.',
          ]),
        LiturgicalSeason.lent => const DirectoryTopic('Quaresma', [
            'A Quaresma são os quarenta dias que preparam a Páscoa. Começa na Quarta-feira de Cinzas e estende-se até à Missa da Ceia do Senhor, na Quinta-feira Santa.',
            'A Igreja propõe três caminhos, os mesmos que o Evangelho do primeiro dia anuncia: a oração, o jejum e a esmola. Não são exercícios de mérito próprio, mas o modo concreto de preparar o batismo dos catecúmenos e de renovar o dos já batizados.',
            'A cor é roxa; o Aleluia cala-se e o Glória só volta nas solenidades. No quarto domingo — *Laetare* — o rosa antecipa a alegria pascal.',
          ]),
        LiturgicalSeason.triduum => const DirectoryTopic('Tríduo Pascal', [
            'O Tríduo Pascal é o centro de todo o ano litúrgico. Não são três celebrações separadas, mas uma só, distribuída por três dias: começa na Missa vespertina da Ceia do Senhor, tem o seu coração na Vigília Pascal e termina nas Vésperas do Domingo de Páscoa.',
            'Na Quinta-feira Santa celebra-se a instituição da Eucaristia e do sacerdócio, e o lava-pés. Na Sexta-feira Santa não há Missa: a Igreja adora a Cruz e ouve a Paixão. O Sábado Santo é dia de silêncio junto ao sepulcro, sem liturgia própria até à noite.',
            'A Vigília Pascal é "a mãe de todas as vigílias": o fogo novo, o Exsultet, as leituras que percorrem a história da salvação, o batismo e, enfim, o Aleluia que volta.',
          ]),
        LiturgicalSeason.easter => const DirectoryTopic('Tempo Pascal', [
            'Os cinquenta dias entre a Páscoa e o Pentecostes são celebrados "como um só dia de festa, como um grande domingo". É o tempo mais antigo e mais importante do calendário cristão.',
            'A Oitava da Páscoa — os oito dias que se seguem ao Domingo de Páscoa — é celebrada inteira como solenidade. O tempo culmina em Pentecostes, com o dom do Espírito Santo à Igreja.',
            'A cor é branca (vermelha em Pentecostes), o círio pascal arde junto ao altar e o Aleluia acompanha toda a liturgia.',
          ]),
        LiturgicalSeason.ordinary => DirectoryTopic('Tempo Comum', [
            'O Tempo Comum não é tempo "menor": são as trinta e quatro semanas em que a Igreja percorre, domingo após domingo, o mistério de Cristo na sua totalidade, sem uma festa que o concentre num aspecto.',
            'Corre em dois blocos: do Batismo do Senhor até à Quarta-feira de Cinzas, e do dia seguinte a Pentecostes até ao sábado antes do Advento. A numeração das semanas continua de um bloco para o outro.',
            if (day.week != null)
              'Estamos na ${day.week}ª semana do Tempo Comum. A cor é verde, cor da esperança e do crescimento paciente.'
            else
              'A cor é verde, cor da esperança e do crescimento paciente.',
          ]),
      };

  // ── Particular celebrations ───────────────────────────────────────────────
  DirectoryTopic? _celebration(LiturgicalDay day) {
    final n = day.celebration;
    bool has(String s) => n.contains(s);

    if (has('Cinzas')) {
      return const DirectoryTopic('Quarta-feira de Cinzas', [
        'A Quaresma abre-se com a imposição das cinzas, feitas dos ramos bentos do Domingo de Ramos do ano anterior. O gesto é antiquíssimo e diz duas coisas ao mesmo tempo: "Lembra-te de que és pó e ao pó voltarás" e "Convertei-vos e crede no Evangelho".',
        'É um dos dois únicos dias do ano em que a Igreja universal manda jejuar e abster-se de carne — o outro é a Sexta-feira Santa.',
      ]);
    }
    if (has('Ramos')) {
      return const DirectoryTopic('Domingo de Ramos na Paixão do Senhor', [
        'Abre a Semana Santa com dois movimentos que não se contradizem: a procissão festiva dos ramos, que recorda a entrada de Jesus em Jerusalém, e logo a seguir a leitura solene da Paixão.',
        'A cor é vermelha, cor do martírio: a aclamação e a cruz pertencem à mesma semana e ao mesmo Rei.',
      ]);
    }
    if (has('Quinta-feira Santa')) {
      return const DirectoryTopic('Quinta-feira Santa', [
        'A Missa da Ceia do Senhor celebra a instituição da Eucaristia e do sacerdócio ministerial, e o mandamento novo do amor, significado no lava-pés.',
        'No fim, o Santíssimo é transferido para um lugar de reserva e o altar é despojado. A Igreja permanece em adoração; não há despedida, porque a celebração continua no dia seguinte.',
      ]);
    }
    if (has('Sexta-feira Santa')) {
      return const DirectoryTopic('Sexta-feira Santa da Paixão do Senhor', [
        'É o único dia do ano em que não se celebra a Missa. A liturgia tem três partes: a Palavra, com a Paixão segundo São João; a oração universal pela Igreja e pelo mundo inteiro; e a adoração da Cruz.',
        'Dia de jejum e abstinência em toda a Igreja.',
      ]);
    }
    if (has('Sábado Santo')) {
      return const DirectoryTopic('Sábado Santo', [
        'A Igreja permanece junto ao sepulcro do Senhor, em oração e silêncio. Não há celebração da Eucaristia nem outra liturgia própria durante o dia.',
        'Tudo espera a noite: a Vigília Pascal, que já pertence ao Domingo da Ressurreição.',
      ]);
    }
    if (has('Domingo de Páscoa')) {
      return const DirectoryTopic('Domingo de Páscoa', [
        'A festa das festas. Tudo no calendário cristão se ordena a este dia: as datas móveis do ano inteiro dependem dele, e todo domingo é uma pequena Páscoa.',
        'A Oitava que se segue prolonga a solenidade por oito dias, como se fosse um único domingo dilatado.',
      ]);
    }
    if (has('Divina Misericórdia')) {
      return const DirectoryTopic('2º Domingo da Páscoa', [
        'Encerra a Oitava da Páscoa. O Evangelho é o de Tomé, que crê ao ver as chagas do Ressuscitado.',
        'Desde o ano 2000 é também chamado Domingo da Divina Misericórdia.',
      ]);
    }
    if (has('Ascensão')) {
      return const DirectoryTopic('Ascensão do Senhor', [
        'Quarenta dias depois da Páscoa, Cristo é elevado ao céu. Não é uma despedida: é a nossa humanidade que entra na glória de Deus, e a Igreja que recebe a missão de anunciar o Evangelho a toda a criatura.',
        'Solenidade e, no direito universal, dia de preceito. Várias conferências episcopais transferem a celebração para o domingo seguinte.',
      ]);
    }
    if (has('Pentecostes')) {
      return const DirectoryTopic('Pentecostes', [
        'Cinquenta dias depois da Páscoa, o Espírito Santo desce sobre os Apóstolos. É o termo do Tempo Pascal e o nascimento da Igreja enviada ao mundo.',
        'A cor é vermelha, cor do fogo. Com este domingo o círio pascal deixa o seu lugar junto ao altar.',
      ]);
    }
    if (has('Trindade')) {
      return const DirectoryTopic('Santíssima Trindade', [
        'No primeiro domingo depois de Pentecostes a Igreja contempla não um episódio da salvação, mas Aquele que a realiza: um só Deus, Pai, Filho e Espírito Santo.',
        'É a festa do mistério central da fé cristã, aquele de que todos os outros dependem.',
      ]);
    }
    if (has('Corpo e Sangue')) {
      return const DirectoryTopic('Santíssimo Corpo e Sangue de Cristo', [
        'Corpus Christi celebra a presença real de Cristo na Eucaristia. Nasceu no século XIII, e a tradição atribui a São Tomás de Aquino os textos do seu ofício.',
        'A procissão com o Santíssimo, onde se realiza, leva à rua aquilo que se celebra no altar.',
      ]);
    }
    if (has('Sagrado Coração')) {
      return const DirectoryTopic('Sagrado Coração de Jesus', [
        'Na sexta-feira depois do segundo domingo após Pentecostes, a Igreja contempla o amor de Cristo sob o sinal do seu Coração aberto na cruz.',
        'É devoção antiga, difundida sobretudo a partir das revelações a Santa Margarida Maria Alacoque no século XVII.',
      ]);
    }
    if (has('Rei do Universo')) {
      return const DirectoryTopic('Cristo Rei do Universo', [
        'O último domingo do ano litúrgico proclama que a história tem um termo e um Senhor. Instituída por Pio XI em 1925, a solenidade fecha o ciclo antes que o Advento o recomece.',
        'O reino que se celebra não é de poder, mas "reino de verdade e de vida, reino de santidade e de graça, reino de justiça, de amor e de paz".',
      ]);
    }
    if (has('Sagrada Família')) {
      return const DirectoryTopic('Sagrada Família', [
        'No domingo dentro da Oitava do Natal, a Igreja olha para a casa de Nazaré. O Filho de Deus quis crescer numa família concreta, com um pai e uma mãe, sujeito a eles.',
        'Quando o Natal cai num domingo, a festa celebra-se a 30 de dezembro.',
      ]);
    }
    if (has('Batismo do Senhor')) {
      return const DirectoryTopic('Batismo do Senhor', [
        'No Jordão, Jesus assume a condição dos pecadores e o Pai o manifesta como Filho amado. É o começo da sua vida pública.',
        'A festa encerra o Tempo do Natal: no dia seguinte começa o Tempo Comum.',
      ]);
    }
    if (has('Epifania')) {
      return const DirectoryTopic('Epifania do Senhor', [
        'Epifania quer dizer "manifestação". Os magos vindos do Oriente são as primícias das nações que reconhecem o Rei recém-nascido: a salvação não é de um povo só.',
        'A tradição junta a esta manifestação outras duas — o batismo no Jordão e o milagre de Caná.',
      ]);
    }
    if (has('Todos os Santos')) {
      return const DirectoryTopic('Todos os Santos', [
        'A Igreja celebra de uma vez todos os santos do céu, os que têm dia próprio no calendário e a multidão incontável dos que não têm.',
        'É solenidade e, no direito universal, dia de preceito.',
      ]);
    }
    if (has('Fiéis Defuntos')) {
      return const DirectoryTopic('Comemoração de Todos os Fiéis Defuntos', [
        'No dia seguinte a Todos os Santos, a Igreja reza pelos que morreram e ainda se purificam. A cor pode ser roxa, e a oração pelos mortos é uma das obras de misericórdia mais antigas dos cristãos.',
        'Cada sacerdote pode celebrar três Missas neste dia.',
      ]);
    }
    if (has('Imaculada Conceição')) {
      return const DirectoryTopic('Imaculada Conceição', [
        'Maria foi preservada de todo pecado desde o primeiro instante da sua existência, em vista dos méritos de Cristo. O dogma foi definido por Pio IX em 1854.',
        'Solenidade celebrada a 8 de dezembro, dentro do Advento, e dia de preceito no direito universal.',
      ]);
    }
    if (has('Assunção')) {
      return const DirectoryTopic('Assunção de Nossa Senhora', [
        'Terminado o curso da vida terrena, Maria foi elevada em corpo e alma à glória do céu — dogma definido por Pio XII em 1950.',
        'Nela vê-se já cumprido aquilo que é esperança de toda a Igreja.',
      ]);
    }
    if (has('Anunciação')) {
      return const DirectoryTopic('Anunciação do Senhor', [
        'Nove meses antes do Natal celebra-se o momento em que o Verbo se fez carne no seio da Virgem. É solenidade do Senhor, embora tenha Maria por protagonista visível.',
        'Quando cai na Semana Santa ou na Oitava da Páscoa, é transferida para depois do tempo impedido.',
      ]);
    }
    if (has('Transfiguração')) {
      return const DirectoryTopic('Transfiguração do Senhor', [
        'No monte, diante de três discípulos, a glória de Cristo transparece por um instante. A luz que ali se vê é a mesma que a Páscoa revelará.',
        'Festa do Senhor, tem precedência sobre o domingo do Tempo Comum em que caia.',
      ]);
    }
    if (has('Exaltação da Santa Cruz')) {
      return const DirectoryTopic('Exaltação da Santa Cruz', [
        'A Igreja venera o instrumento da Paixão como trono do Rei: a cruz não é derrota, mas o modo escolhido para vencer.',
        'A cor é vermelha, e a festa tem precedência sobre o domingo do Tempo Comum.',
      ]);
    }
    if (has('Natal do Senhor')) {
      return const DirectoryTopic('Natal do Senhor', [
        'A Igreja celebra o nascimento de Cristo com quatro Missas próprias — da vigília, da noite, da aurora e do dia — cada uma com os seus textos.',
        'A solenidade prolonga-se por uma oitava inteira e é dia de preceito.',
      ]);
    }
    if (has('Oitava da Páscoa')) {
      return const DirectoryTopic('Oitava da Páscoa', [
        'Cada um dos oito dias que se seguem ao Domingo de Páscoa é celebrado como solenidade do Senhor. Nenhuma outra festa pode ocupá-los.',
        'É a Páscoa dilatada: um só dia de festa que dura uma semana.',
      ]);
    }
    if (has('Oitava do Natal')) {
      return const DirectoryTopic('Oitava do Natal', [
        'Os oito dias a partir de 25 de dezembro formam uma unidade: cada um deles participa da solenidade do Natal.',
        'A oitava fecha-se a 1 de janeiro, na solenidade de Santa Maria, Mãe de Deus.',
      ]);
    }
    if (has('Semana Santa')) {
      return const DirectoryTopic('Semana Santa', [
        'A última semana da Quaresma acompanha dia a dia os passos que levam à Paixão. Nenhuma festa de santo pode ser celebrada nestes dias.',
        'A partir da Missa da Ceia do Senhor começa o Tríduo Pascal.',
      ]);
    }
    return null;
  }

  // ── Colour ────────────────────────────────────────────────────────────────
  DirectoryTopic _color(LiturgicalColor c) => switch (c) {
        LiturgicalColor.green => const DirectoryTopic('Verde', [
            'O verde acompanha o Tempo Comum. É a cor da esperança e da vida que cresce sem alarde — o tempo em que a Igreja caminha e amadurece.',
          ]),
        LiturgicalColor.white => const DirectoryTopic('Branco', [
            'O branco é a cor da luz, da alegria e da pureza. Usa-se no Natal e na Páscoa, nas festas do Senhor que não sejam da Paixão, nas de Nossa Senhora, dos anjos e dos santos que não foram mártires.',
          ]),
        LiturgicalColor.red => const DirectoryTopic('Vermelho', [
            'O vermelho diz duas coisas: o fogo do Espírito e o sangue derramado. Por isso é a cor do Domingo de Ramos e da Sexta-feira Santa, do Pentecostes, das festas dos Apóstolos e de todos os mártires.',
          ]),
        LiturgicalColor.purple => const DirectoryTopic('Roxo', [
            'O roxo marca os tempos de preparação e conversão: o Advento e a Quaresma. Pode usar-se também nas celebrações pelos defuntos.',
          ]),
        LiturgicalColor.rose => const DirectoryTopic('Rosa', [
            'O rosa é permitido apenas dois dias no ano: no domingo *Gaudete*, no Advento, e no domingo *Laetare*, na Quaresma. Em ambos a alegria já se antecipa no meio da espera.',
          ]),
      };

  // ── Rank ──────────────────────────────────────────────────────────────────
  DirectoryTopic _rank(LiturgicalRank r) => switch (r) {
        LiturgicalRank.solemnity => const DirectoryTopic('Solenidade', [
            'A solenidade é o grau mais alto de celebração. Tem Glória e Credo, leituras próprias e, quando é do Senhor, precede o domingo em que caia.',
            'Algumas solenidades são dias de preceito; quando impedidas por um tempo mais forte, são transferidas em vez de suprimidas.',
          ]),
        LiturgicalRank.feast => const DirectoryTopic('Festa', [
            'A festa celebra-se dentro do dia, com Glória mas sem Credo (salvo se for festa do Senhor num domingo).',
            'As festas do Senhor têm precedência sobre os domingos do Tempo Comum; as dos santos, não.',
          ]),
        LiturgicalRank.memorial => const DirectoryTopic('Memória obrigatória', [
            'A memória insere-se na celebração do dia, sem a substituir. Nos tempos fortes — Quaresma, Advento a partir de 17 de dezembro, Oitava do Natal — cede o lugar à féria e pode ser feita apenas como comemoração.',
          ]),
        LiturgicalRank.optionalMemorial =>
          const DirectoryTopic('Memória facultativa', [
            'A memória facultativa pode ser celebrada ou omitida, a critério de quem preside. Se não for tomada, celebra-se a féria do dia.',
          ]),
        LiturgicalRank.commemoration => const DirectoryTopic('Comemoração', [
            'A comemoração recorda a celebração sem lhe dar o grau de memória: entra na oração do dia sem mudar o resto da liturgia.',
          ]),
        LiturgicalRank.weekday => const DirectoryTopic('Féria', [
            'Féria é o dia da semana que não tem celebração própria. Longe de ser um dia vazio, é onde a liturgia percorre continuamente a Escritura, semana após semana.',
          ]),
      };

  // ── Practical notes ───────────────────────────────────────────────────────
  List<String> _practical(LiturgicalDay day) {
    final o = day.observance;
    return [
      if (o.isHolyDayOfObligation && day.date.weekday == DateTime.sunday)
        'Domingo: dia de preceito. A participação na Missa é obrigatória.',
      if (o.isHolyDayOfObligation && day.date.weekday != DateTime.sunday)
        'Dia de preceito no direito universal. Algumas conferências episcopais transferem-no para o domingo ou dispensam da obrigação — vale o calendário da sua diocese.',
      if (o.isFastDay)
        'Dia de jejum e abstinência: uma só refeição completa e nada de carne. Obriga ao jejum dos 18 aos 59 anos, e à abstinência a partir dos 14.',
      if (o.isAbstinenceDay && !o.isFastDay)
        'Sexta-feira: dia de abstinência de carne no direito universal, a partir dos 14 anos. A conferência episcopal pode substituí-la por outra forma de penitência.',
      if (o.isInOctave)
        'Dia dentro de uma oitava: a solenidade prolonga-se e nenhuma outra celebração a substitui.',
      if (day.optionalMemorials.isNotEmpty)
        'Hoje pode celebrar-se também: ${day.optionalMemorials.map((m) => m.name).join('; ')}.',
    ];
  }
}
