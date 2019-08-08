#!/usr/bin/python
import sys
lines = sys.stdin.readlines()
for l in lines:
    print '"' + l.strip() + '"'
