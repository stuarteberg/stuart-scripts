#!/bin/env python3
"""
A wrapper around the tqdm CLI, more suitable for
logging to a file in a long-running batch program.
Monkey-batches tqdm to print each update on a new
line instead of clearing the line.
"""
import tqdm
import tqdm._main

#
# https://github.com/tqdm/tqdm/issues/750#issuecomment-537558122
#
@staticmethod
def status_printer(file):
    """
    Manage the printing and in-place updating of a line of characters.
    Note that if the string is longer than a line, then in-place
    updating may not work (it will print a new line at each refresh).
    """
    fp = file
    fp_flush = getattr(fp, 'flush', lambda: None)  # pragma: no cover

    def fp_write(s):
        fp.write(str(s))
        fp_flush()

    last_len = [0]

    def print_status(s):
        len_s = len(s)
        fp_write('\n' + s + (' ' * max(last_len[0] - len_s, 0)))
        last_len[0] = len_s

    return print_status

# Monkey-patch status_printer to use \n instead of \r
tqdm.tqdm.status_printer = status_printer
tqdm._main.main()
