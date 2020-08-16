#!/groups/flyem/proj/cluster/miniforge/bin/python
import sys
lines = sys.stdin.readlines()

if len(lines) == 0:
    sys.exit(0)

if lines[0].startswith("No"):
    print(lines[0])
    sys.exit(0)

try:
    i = 0
    print(lines[i], end='')
    i = 1

    submit_col = lines[0].split().index('SUBMIT_TIME')
    jobid_col = lines[0].split().index('JOBID')

    # There are three submit cols (e.g. 'Nov 14 17:29:58'),
    # so sort by all three, then by job id
    print(''.join(sorted(lines[i:], key=lambda l: (l.split()[submit_col:submit_col+3], l.split()[jobid_col]))))
except:
    # If we couldn't parse the input, maybe the user specified their own flags
    print(''.join(lines[i:]))
