#!/bin/bash

set -e

text=$(</dev/stdin)
text_lines=$(echo "${text}" | wc -l)
term_lines=$(tput lines)

if [[ $text_lines -lt $term_lines ]]; then
    echo "${text}"
else
    echo "${text}" | less -SR
fi
