#!/usr/bin/env python3
"""Seeds book names and abbreviations in English, Italian, Spanish and French
(the app already has Portuguese), so the whole reader follows the app language.
Names follow each language's traditional Catholic usage (Douay for English,
CEI for Italian, Biblia de Jerusalén for Spanish, Bible de Jérusalem for
French).

Usage: python3 -I book_names.py BIBLE.sqlite
"""
import sqlite3
import sys

IDS = ('gn ex lv nm dt jo jgs rt 1sm 2sm 1kgs 2kgs 1chr 2chr ezr neh tb jdt est 1mac 2mac jb ps prv eccl sg ws sir is '
       'jer lam bar ez dn hos jl am ob jon mi na hb zep hg zec mal mt mk lk jn acts rom 1cor 2cor gal eph phil col '
       '1thes 2thes 1tm 2tm tit phlm heb jas 1pt 2pt 1jn 2jn 3jn jud rv').split()

# name|abbrev, in canonical order
NAMES = {
    'en': """Genesis|Gn;Exodus|Ex;Leviticus|Lv;Numbers|Nm;Deuteronomy|Dt;Joshua|Jos;Judges|Jgs;Ruth|Ru;1 Samuel|1Sm;2 Samuel|2Sm;
1 Kings|1Kgs;2 Kings|2Kgs;1 Chronicles|1Chr;2 Chronicles|2Chr;Ezra|Ezr;Nehemiah|Neh;Tobit|Tb;Judith|Jdt;Esther|Est;
1 Maccabees|1Mc;2 Maccabees|2Mc;Job|Jb;Psalms|Ps;Proverbs|Prv;Ecclesiastes|Eccl;Song of Songs|Sg;Wisdom|Wis;Sirach|Sir;
Isaiah|Is;Jeremiah|Jer;Lamentations|Lam;Baruch|Bar;Ezekiel|Ez;Daniel|Dn;Hosea|Hos;Joel|Jl;Amos|Am;Obadiah|Ob;Jonah|Jon;
Micah|Mi;Nahum|Na;Habakkuk|Hb;Zephaniah|Zep;Haggai|Hg;Zechariah|Zec;Malachi|Mal;Matthew|Mt;Mark|Mk;Luke|Lk;John|Jn;
Acts of the Apostles|Acts;Romans|Rom;1 Corinthians|1Cor;2 Corinthians|2Cor;Galatians|Gal;Ephesians|Eph;Philippians|Phil;
Colossians|Col;1 Thessalonians|1Thes;2 Thessalonians|2Thes;1 Timothy|1Tm;2 Timothy|2Tm;Titus|Ti;Philemon|Phlm;
Hebrews|Heb;James|Jas;1 Peter|1Pt;2 Peter|2Pt;1 John|1Jn;2 John|2Jn;3 John|3Jn;Jude|Jude;Revelation|Rv""",
    'it': """Genesi|Gn;Esodo|Es;Levitico|Lv;Numeri|Nm;Deuteronomio|Dt;Giosuè|Gs;Giudici|Gdc;Rut|Rt;1 Samuele|1Sam;2 Samuele|2Sam;
1 Re|1Re;2 Re|2Re;1 Cronache|1Cr;2 Cronache|2Cr;Esdra|Esd;Neemia|Ne;Tobia|Tb;Giuditta|Gdt;Ester|Est;
1 Maccabei|1Mac;2 Maccabei|2Mac;Giobbe|Gb;Salmi|Sal;Proverbi|Pr;Qoèlet|Qo;Cantico dei Cantici|Ct;Sapienza|Sap;Siracide|Sir;
Isaia|Is;Geremia|Ger;Lamentazioni|Lam;Baruc|Bar;Ezechiele|Ez;Daniele|Dn;Osea|Os;Gioele|Gl;Amos|Am;Abdia|Abd;Giona|Gio;
Michea|Mi;Naum|Na;Abacuc|Ab;Sofonia|Sof;Aggeo|Ag;Zaccaria|Zc;Malachia|Ml;Matteo|Mt;Marco|Mc;Luca|Lc;Giovanni|Gv;
Atti degli Apostoli|At;Romani|Rm;1 Corinzi|1Cor;2 Corinzi|2Cor;Galati|Gal;Efesini|Ef;Filippesi|Fil;
Colossesi|Col;1 Tessalonicesi|1Ts;2 Tessalonicesi|2Ts;1 Timoteo|1Tm;2 Timoteo|2Tm;Tito|Tt;Filemone|Fm;
Ebrei|Eb;Giacomo|Gc;1 Pietro|1Pt;2 Pietro|2Pt;1 Giovanni|1Gv;2 Giovanni|2Gv;3 Giovanni|3Gv;Giuda|Gd;Apocalisse|Ap""",
    'es': """Génesis|Gn;Éxodo|Ex;Levítico|Lv;Números|Nm;Deuteronomio|Dt;Josué|Jos;Jueces|Jue;Rut|Rut;1 Samuel|1Sam;2 Samuel|2Sam;
1 Reyes|1Re;2 Reyes|2Re;1 Crónicas|1Cr;2 Crónicas|2Cr;Esdras|Esd;Nehemías|Neh;Tobías|Tob;Judit|Jdt;Ester|Est;
1 Macabeos|1Mac;2 Macabeos|2Mac;Job|Job;Salmos|Sal;Proverbios|Prov;Eclesiastés|Ecl;Cantar de los Cantares|Cant;Sabiduría|Sab;Eclesiástico|Eclo;
Isaías|Is;Jeremías|Jer;Lamentaciones|Lam;Baruc|Bar;Ezequiel|Ez;Daniel|Dn;Oseas|Os;Joel|Jl;Amós|Am;Abdías|Abd;Jonás|Jon;
Miqueas|Miq;Nahúm|Nah;Habacuc|Hab;Sofonías|Sof;Ageo|Ag;Zacarías|Zac;Malaquías|Mal;Mateo|Mt;Marcos|Mc;Lucas|Lc;Juan|Jn;
Hechos de los Apóstoles|Hch;Romanos|Rom;1 Corintios|1Cor;2 Corintios|2Cor;Gálatas|Gál;Efesios|Ef;Filipenses|Flp;
Colosenses|Col;1 Tesalonicenses|1Tes;2 Tesalonicenses|2Tes;1 Timoteo|1Tim;2 Timoteo|2Tim;Tito|Tit;Filemón|Flm;
Hebreos|Heb;Santiago|Sant;1 Pedro|1Pe;2 Pedro|2Pe;1 Juan|1Jn;2 Juan|2Jn;3 Juan|3Jn;Judas|Jds;Apocalipsis|Ap""",
    'fr': """Genèse|Gn;Exode|Ex;Lévitique|Lv;Nombres|Nb;Deutéronome|Dt;Josué|Jos;Juges|Jg;Ruth|Rt;1 Samuel|1S;2 Samuel|2S;
1 Rois|1R;2 Rois|2R;1 Chroniques|1Ch;2 Chroniques|2Ch;Esdras|Esd;Néhémie|Ne;Tobie|Tb;Judith|Jdt;Esther|Est;
1 Maccabées|1M;2 Maccabées|2M;Job|Jb;Psaumes|Ps;Proverbes|Pr;Ecclésiaste|Qo;Cantique des Cantiques|Ct;Sagesse|Sg;Siracide|Si;
Isaïe|Is;Jérémie|Jr;Lamentations|Lm;Baruch|Ba;Ézéchiel|Ez;Daniel|Dn;Osée|Os;Joël|Jl;Amos|Am;Abdias|Ab;Jonas|Jon;
Michée|Mi;Nahum|Na;Habacuc|Ha;Sophonie|So;Aggée|Ag;Zacharie|Za;Malachie|Ml;Matthieu|Mt;Marc|Mc;Luc|Lc;Jean|Jn;
Actes des Apôtres|Ac;Romains|Rm;1 Corinthiens|1Co;2 Corinthiens|2Co;Galates|Ga;Éphésiens|Ep;Philippiens|Ph;
Colossiens|Col;1 Thessaloniciens|1Th;2 Thessaloniciens|2Th;1 Timothée|1Tm;2 Timothée|2Tm;Tite|Tt;Philémon|Phm;
Hébreux|He;Jacques|Jc;1 Pierre|1P;2 Pierre|2P;1 Jean|1Jn;2 Jean|2Jn;3 Jean|3Jn;Jude|Jude;Apocalypse|Ap""",
}


def main(db):
    con = sqlite3.connect(db)
    for lang, raw in NAMES.items():
        pairs = [x.strip().split('|') for x in raw.replace('\n', '').split(';')]
        assert len(pairs) == len(IDS), (lang, len(pairs))
        con.executemany('INSERT OR REPLACE INTO book_name(book_id,lang,name,abbrev) VALUES(?,?,?,?)',
                        [(i, lang, n, a) for i, (n, a) in zip(IDS, pairs)])
    con.commit()
    print('book names:', dict(con.execute('select lang,count(*) from book_name group by 1').fetchall()))


if __name__ == '__main__':
    main(sys.argv[1])
