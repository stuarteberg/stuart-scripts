#!/bin/bash

# Replace tabs in the given file(s) with 4 spaces
sed -i '' $'s/\t/    /g' "$@"
