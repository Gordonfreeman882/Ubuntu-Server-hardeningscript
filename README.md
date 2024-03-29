# Ubuntu Harderscript v.0.0.6

# content
* [Features](#Features)
* [Optional features](#Optional%20features)
* [Requirements](#Requirements)
* [Future updates](#Future%20updates)
* [Usage](#Usage)

# Features:
- languagesupport for german and english
- update system
- install fail2ban, sudo, dpkg-dev
- sets automaticly different dpkg-buildlfags
- log file under /tmp/harderscript.log
- clean up process for uneeded packages through apt

# Optional features:
- install iptables-persistent
- install additional packages via name for apt during script routine
- harden ssh-server
- setup ssh login banner
- create new user with sudo rights
- rootkit-search with rkhunter

# Requirements:
- tested on fresh installed Ubuntu 22.04 LTS, 20.04 LTS, 18.04 LTS, 16.04 LTS [Server]
- run script as root or as user with root priviliges
- optional but important, openssh-server

# Future updates:
- smarter language detection routine
- support for Debian
- improve colorful output
- disable ipv6

# Usage:

```
$ git clone https://github.com/Gordonfreeman882/Ubuntu-Server-hardeningscript.git
$ cd Ubuntu-Server-hardeningscript
$ sudo sh harderscript.sh
```

Feel free to improve or to add usefull parts.
