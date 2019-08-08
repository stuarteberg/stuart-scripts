#!/usr/bin/env python

import os
import sys
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--spaces', type=int, default=4)
    parser.add_argument('-o', '--overwrite', action='store_true')
    parser.add_argument('input_paths', nargs='+')
    args = parser.parse_args()

    found_tabs = False
    for input_path in args.input_paths:
        with open(input_path, 'r') as f:
            text = f.read()
            if '\t' in text:
                found_tabs = True
            new_text = text.replace('\t', ' '*args.spaces)

        output_path = input_path + '.notabs'
        with open(output_path, 'w') as f:
            f.write(new_text)

        if args.overwrite:
            os.rename(output_path, input_path)

        if not found_tabs:
            print("No tabs found")

if __name__ == "__main__":
    main()
