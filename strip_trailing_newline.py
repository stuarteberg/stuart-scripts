#/usr/bin/env python
import sys
input = sys.stdin.read()
if input[-1] == '\n':
    input = input[:-1]
sys.stdout.write(input)