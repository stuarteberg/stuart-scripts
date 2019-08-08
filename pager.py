#!/miniforge/bin/python3.7
"""
A wrapper for 'less' that can be used as a git pager.
It achieves the same effect as 'less -F -X', but doesn't interfere with scrolling in iTerm2.

Most people recommend setting your git pager as follows:

  git config --global --replace-all core.pager "less -F -X"

The problem with 'less -F -X' is that it prevents the scroll wheel from working in iTerm2.
The probelm with 'less -F' (without -X) is that content that is less than one terminal's
worth will be immediately cleared, making it look like there was no content at all.

If we simply implement the '-F' functionality ourselves, then we can avoid using less
in the case of small outputs.
"""

import sys
import subprocess

input = sys.stdin.buffer.read()
input_lines = 1 + sum(1 for c in input.decode('utf-8') if c == '\n')

term_lines = subprocess.run(['tput', 'lines'], capture_output=True, check=True).stdout
term_lines = int(term_lines.decode('utf-8'))

if input_lines < term_lines:
    sys.stdout.buffer.write(input)
else:
    subprocess.run(['less', '-SR'], input=input)
