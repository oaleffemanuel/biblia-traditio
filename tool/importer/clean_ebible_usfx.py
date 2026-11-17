#!/usr/bin/env python3
"""Normalises an eBible.org USFX file (e.g. the Douay-Rheims, engDRA) to the
flat shape UsfxParser reads: drops Strong's word wrappers (<w s=…>), footnotes
and cross-references, and simplifies verse markers to <v id="n"/> / <ve/>.

Usage: python3 -I clean_ebible_usfx.py IN.xml OUT.xml
"""
import re
import sys

src = open(sys.argv[1], encoding='utf-8').read()
src = re.sub(r'<f\b[^>]*>.*?</f>', '', src, flags=re.S)
src = re.sub(r'<x\b[^>]*>.*?</x>', '', src, flags=re.S)
src = re.sub(r'</?w\b[^>]*>', '', src)
# Paragraph and poetry wrappers: keep the text, drop the nesting.
src = re.sub(r'</?(p|q|qt|wj|b)\b[^>]*>', ' ', src)
src = re.sub(r'<v id="([^"]+)"[^>]*/>', r'<v id="\1"/>', src)
src = re.sub(r'<ve\s*/>', '<ve/>', src)
open(sys.argv[2], 'w', encoding='utf-8').write(src)
