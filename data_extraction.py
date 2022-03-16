# -*-coding:Latin-1 -*

import subprocess

p = subprocess.Popen("df -h", shell=True, stdout=subprocess.PIPE)
out = p.stdout.readlines()
for line in out:
	print line.strip()


