#!/usr/bin/env python
import os
import re
import sys
import argparse

##
## Example Usage:
## pysed.py --line-prep='m = re.search("User ([^:]+):", line)' 'm.groups()[0] if m else None' < log.txt
##

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--init', required=False)
parser.add_argument('-l', '--line-prep', required=False)
parser.add_argument('output_expression', nargs='?')
args = parser.parse_args()

if args.init:
    exec(args.init)

for line in sys.stdin:
    line = line.rstrip()

    if args.line_prep:
        exec(args.line_prep)

    if args.output_expression:
        newline = eval(args.output_expression)
        if newline is not None:
            print(newline)
