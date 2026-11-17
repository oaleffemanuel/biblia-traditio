#!/usr/bin/env python3
"""Bakes the responsorial-psalm refrain of every day into
assets/lectionary/refrains.json, so the Liturgy tab works offline.

Source: the community API liturgia.up.railway.app (Dancrf/liturgia-diaria),
which mirrors the CNBB daily liturgy. The refrain text belongs to the CNBB
Lectionary — an unofficial source chosen by the team (2026-11-17).

Incremental: days already in the file are kept; only missing days are asked.
Usage: python3 -I tool/fetch_psalm_refrains.py 2026 2027 [--out assets/lectionary/refrains.json]
"""
import argparse
import datetime as dt
import json
import os
import time
import urllib.request

API = 'https://liturgia.up.railway.app/v2/?dia={d}&mes={m}&ano={y}'


def fetch(day):
    url = API.format(d=day.day, m=day.month, y=day.year)
    req = urllib.request.Request(url, headers={'User-Agent': 'biblia-patristica-build/1.0'})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except Exception:
            time.sleep(2 * (attempt + 1))
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('years', nargs='+', type=int)
    ap.add_argument('--out', default='assets/lectionary/refrains.json')
    a = ap.parse_args()
    data = {'source': 'Liturgia diária (CNBB) via liturgia.up.railway.app', 'days': {}}
    if os.path.exists(a.out):
        data = json.load(open(a.out, encoding='utf-8'))
    days = data['days']
    missing = 0
    for y in a.years:
        d = dt.date(y, 1, 1)
        while d.year == y:
            key = d.isoformat()
            if key not in days:
                j = fetch(d)
                psalms = ((j or {}).get('leituras') or {}).get('salmo') or []
                if psalms:
                    # Several options on some days: the first is the one appointed.
                    days[key] = [{'ref': (p.get('referencia') or '').strip(),
                                  'refrain': (p.get('refrao') or '').strip()}
                                 for p in psalms if (p.get('refrao') or '').strip()]
                else:
                    missing += 1
                time.sleep(0.3)
            d += dt.timedelta(days=1)
        json.dump(data, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        print(y, 'done')
    print('days with refrain:', sum(1 for v in days.values() if v), '· missing:', missing)


if __name__ == '__main__':
    main()
