Ubuntu Harderscript v.0.0.5

Features:
- languagesupport for german and english
- update system
- install fail2ban, sudo, dpkg-dev
- sets automaticly different dpkg-buildlfags
- log file under /tmp/harderscript.log
- clean up process for uneeded packages through apt

Optional features:
- install iptables-persistent
- install additional packages via name for apt during script routine
- deactivate root-login on ssh-server
- creates new user with sudo rights
- rootkit-search with rkhunter
- setup ssh login banner

Requirements:
- tested on fresh installed Ubuntu 18.04 LTS, 16.04 LTS [Server]
- run script as root or as user with root priviliges
- optional but important, openssh-server

Future updates
- smarter language detection routine
- support for Debian
- improve colorful output 

Feel free to improve or to add usefull parts. 
