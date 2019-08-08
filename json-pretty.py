#!/usr/bin/env python
import sys
import json

f_in = sys.stdin
f_out = sys.stdout

if len(sys.argv) >= 2:
    f_in = open(sys.argv[1])

if len(sys.argv) == 3:
    f_out = open(sys.argv[2])

json.dump(json.load(f_in), f_out,
          sort_keys=True, indent=2, separators=(',', ': '))
