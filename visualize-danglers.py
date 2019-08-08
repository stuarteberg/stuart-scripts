import subprocess

fsck_output = subprocess.check_output('git fsck --lost-found', shell=True)

shas = []
for line in fsck_output.split('\n'):
    if line and 'blob' not in line:
        sha = line.split()[-1]
        print sha
        shas.append(sha)

for sha in shas:
    cmd = 'git branch dangler-{} {}'.format(sha[:7], sha)
    print cmd
    subprocess.check_call( cmd, shell=True )

print("DONE.")
