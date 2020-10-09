#!/bin/bash
#var
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
clear
echo "-------------------------------------Systeminformationen-------------------------------------"
echo "Hostname:\t\t"`hostname`
echo "uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
echo "Kernel:\t\t\t"`uname -r`
echo "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
echo "System Main IP:\t\t"`hostname -I`
echo "---------------------------------------------------------------------------------------------"
#Funtkion Warten und Bildschirm aufräumen
clearandsleep() {
  sleep 4s
  clear
}
#Funktion zur Installation von sinnvollen Paketen zur Absicherung
paket() {
  echo "Versuche fail2banserver zu installieren..."
  apt install fail2ban -y
  clearandsleep
  while true
  do
  if [ $lang = de ]
  then
    read -r -p "Soll iptables-persistent installiert werden [y/n]" input
  else
    read -r -p "Do you want iptables-persistent to be installed [y/n]" input
  fi
  case $input in
       [yY][eE][sS]|[yY])
       clear
       if [ $lang = de ]
       then
        echo "Installiere iptables-persistent"
        apt install iptables-persistent -y
        clearandsleep
        echo "Updates und default Pakete sollten installiert sein" >> /tmp/harderscript.log
       else
        clear
        echo "Installing iptables-persistent"
        apt install iptables-persistent -y
        clearandsleep
        echo "Updates und default packages were installed" >> /tmp/harderscript.log
      fi
  break
  ;;
      [nN][oO]|[nN])
      clear
      if [ $lang = de ]
      then
        echo "Iptables-persistent wird nicht installiert!"
        echo "Updates sind installiert, iptables-persistent wurde nicht installiert!" >> /tmp/harderscript.log
        iptables=0
      else
        clear
        echo "I will not install iptables-persistent!"
        echo "Packages updated, iptables-persistent not installed!" >> /tmp/harderscript.log
        iptables=0
      fi
  break
  ;;
      *)
      echo "Invalid input..."
      ;;
esac
done
clearandsleep
}

#Welcher Nutzer bin ich?
nutzer=$(whoami)
rot=root
#Setting script language
while true
do
read -r -p "Please select script language [DE/ENG]" input
case $input in
     [dD][eE]|[dD])
     echo "Scriptsprache: Deutsch"
     lang=de
break
;;
    [eE][nN][gG]|[eE][nN])
echo "Scriptlanguage: english"
lang=en
break
;;
    *)
echo "Invalid input..."
;;
esac
done
if [ $lang = de ]
then
if [ $nutzer = "root" ]
then
  echo "${GREEN}Superuser erfolgreich angemeldet.${NOCOLOR}";
  echo "Lege logfile an...";
  touch /tmp/harderscript.log
  echo "################################" >> /tmp/harderscript.log
  date >> /tmp/harderscript.log
  echo "root started script" >> /tmp/harderscript.log
else
  echo "${RED}Script muss als Root ausgeführt werden${NOCOLOR}"
  exit 0
fi
clearandsleep
#Testen der Internetverbindung
inet=$(ping -c3 1.1.1.1 | grep -i 0% >/dev/null && echo JA || echo Nein)
if [ $inet = "JA" ]
then
  ping -c3 1.1.1.1 | grep -i 0% >> /tmp/harderscript.log
  echo "${GREEN}Internetverbindung vorhanden. Ping erfolgreich${NOCOLOR}"
  clearandsleep
  #Installtion von Updates sowie von Paketen
  echo "Starte updates..."
  sleep 2s
  clear
  apt update && apt upgrade -y
  echo "${GREEN}Updates erfolgreich durch geführt!${NOCOLOR}"
  clearandsleep
  paket
else
  echo "${RED}Schlechte oder keine Internetverbindung${NOCOLOR}"
  echo "Schlechte oder keine Internetverbindung" >> /tmp/harderscript.log
  clearandsleep
  echo "Setzte Script fort..."
  apt update && apt upgrade -y
  clearandsleep
  paket
fi
#Prüfung ob Programme installiert wurden
echo "Prüfe ob Programme Ordnungsgemäß installiert wurden...${RED}!(unstable)!${NOCOLOR}"
clearandsleep
fail2ban=`type -p fail2ban-server`
if [ ! -f "$fail2ban" ]; then
  echo "${RED}Fail2ban könnte fehlen..${NOCOLOR}"
else
  echo "${GREEN}Fail2ban vorhanden!${NOCOLOR}"
fi
if [ $iptables = 0 ]
then
  echo "Iptables nicht zu installation ausgewählt" >> /tmp/harderscript.log
else
iptablesper=$(apt install iptables-persistent | grep -i "ist schon die neueste Version" >/dev/null && echo JA || echo NEIN)
if [ $iptablesper = "JA" ]
then
  echo "iptables-persistent vorhanden!"
  echo "iptables vorhanden" >> /tmp/harderscript.log
else
  echo "${RED}iptables-persistent missing..${NOCOLOR}"
  echo "iptables fehlt?" >> /tmp/harderscript.log
fi
fi
clearandsleep
sudo=`type -p sudo`
if [ ! -f "$sudo" ]; then
  echo "${RED}sudo missing..${NOCOLOR}Installiere"
  sleep 2s
  clear
  apt install sudo -y
  echo "sudo installiert" >> /tmp/harderscript
else
  echo "${GREEN}sudo vorhanden!${NOCOLOR}"
fi
#Zusätzliche Installation von Paketen
y=1
i=0
while [ $y = 1 ]
do
clearandsleep
echo "Moechten Sie ein weiteres Paket installieren? (iftop,screen) [Y/N]"
read package
if [ $package = "N" ] || [ $package = "n" ]
then
  clear
  if [ $i = 0 ]
  then
    echo "Kein Paket zur Installation ausgewählt."
    clearandsleep
  else
    echo "Keine weiteren Pakete zur Installation ausgewählt."
    clearandsleep
  fi
  y=2
else
  clear
  i=$((i + 1 ))
  echo "Bitte geben Sie den Paketnamen an. Paket" $i
  read packagename
  #echo $packagename | cut -d ',' -f1-*
  echo "Paket" $packagename "wird installiert"
  apt install $packagename -y
  echo "zusaetzliches Paket" $packagename >> /tmp/harderscript.log
  clearandsleep
  echo "Pruefe ob " $packagename "installiert wurde...(!unstable!)"
  varpackage=`type -p $packagename`
  if [ ! -f "$packagename" ]; then
    echo $packagename " missing.."
    clearandsleep
  else
    echo $packagename " vorhanden!"
    clearandsleep
  fi
fi
done
#SSH root login deaktivieren
echo "Versuche sshd_config zu finden...."
path=$(find /etc -name sshd_config)
echo $path
while true
do
 read -r -p "War das der richtige Pfad [Y/n] " input

 case $input in
     [yY][eE][sS]|[yY])
 echo "Verbiete Root Login via SSH"
 sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' $path
 echo "SSH Rootlogin verboten" >> /tmp/harderscript.log
 break
 ;;
     [nN][oO]|[nN])
 clear
 echo "${RED}SSH Rootlogin bitte haendisch deaktivieren in SSHD_CONFIG unter PermitRootLogin${NOCOLOR}"
 echo "SSH Rootlogin weiterhin moeglich" >> /tmp/harderscript.log
 break
        ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done
clearandsleep
echo "Achtung dieses Banner kann für den SSH-Login eingestellt werden!"
clearandsleep
echo "                                                                #####
                                                               #######
                  @                                            ##O#O##
 ######          @@#                                           #VVVVV#
   ##             #                                          ##  VVV  ##
   ##         @@@   ### ####   ###    ###  ##### ######     #          ##
   ##        @  @#   ###    ##  ##     ##    ###  ##       #            ##
   ##       @   @#   ##     ##  ##     ##      ###         #            ###
   ##          @@#   ##     ##  ##     ##      ###        QQ#           ##Q
   ##       # @@#    ##     ##  ##     ##     ## ##     QQQQQQ#       #QQQQQQ
   ##      ## @@# #  ##     ##  ###   ###    ##   ##    QQQQQQQ#     #QQQQQQQ
 ############  ###  ####   ####   #### ### ##### ######   QQQQQ#######QQQQQ

    ********************************************************************
    *                                                                  *
    * This system is for the use of authorized users only.  Usage of   *
    * this system may be monitored and recorded by system personnel.   *
    *                                                                  *
    * Anyone using this system expressly consents to such monitoring   *
    * and is advised that if such monitoring reveals possible          *
    * evidence of criminal activity, system personnel may provide the  *
    * evidence from such monitoring to law enforcement officials.      *
    *                                                                  *
    ********************************************************************"
sleep 2s
clearandsleep
while true
do
  read -r -p "Soll das Login-Banner für den SSH-Login verwendet werden? [Y/n] " input
  case $input in
        [yY][eE][sS]|[yY])
        echo "Banner /etc/issue.net" >> $path
        echo "                                                                     #####
                                                                    #######
                       @                                            ##O#O##
      ######          @@#                                           #VVVVV#
        ##             #                                          ##  VVV  ##
        ##         @@@   ### ####   ###    ###  ##### ######     #          ##
        ##        @  @#   ###    ##  ##     ##    ###  ##       #            ##
        ##       @   @#   ##     ##  ##     ##      ###         #            ###
        ##          @@#   ##     ##  ##     ##      ###        QQ#           ##Q
        ##       # @@#    ##     ##  ##     ##     ## ##     QQQQQQ#       #QQQQQQ
        ##      ## @@# #  ##     ##  ###   ###    ##   ##    QQQQQQQ#     #QQQQQQQ
      ############  ###  ####   ####   #### ### ##### ######   QQQQQ#######QQQQQ

         ********************************************************************
         *                                                                  *
         * This system is for the use of authorized users only.  Usage of   *
         * this system may be monitored and recorded by system personnel.   *
         *                                                                  *
         * Anyone using this system expressly consents to such monitoring   *
         * and is advised that if such monitoring reveals possible          *
         * evidence of criminal activity, system personnel may provide the  *
         * evidence from such monitoring to law enforcement officials.      *
         *                                                                  *
         ********************************************************************" >> /etc/issue.net
         echo "SSH Banner eingestellt" >> /tmp/harderscript.log
         break
         ;;
         [nN][oO]|[nN])
         echo "SSH Banner verwurfen"
         echo "SSH Banner verwurfen" >> /tmp/harderscript.log
         break
         ;;
         *)
         echo "Invalid input..."
         ;;
       esac
     done

clearandsleep
echo "Installiere dpkg-dev und setzte Flags..."
echo "Installiere dpkg-dev und setzte Flags..." >> /tmp/harderscript.log
apt install dpkg-dev -y
dpkg-buildflags --get CFLAGS
dpkg-buildflags --get LDFLAGS
dpkg-buildflags --get CPPFLAGS
clearandsleep
while true
do
read -r -p "Soll mittels rkhunter das System auf Schwachstellen, Rootkits etc untersucht werden? !rkhunter wird installiert! [Y/N]" input
case $input in
     [yY][eE][sS]|[yY])
     apt install rkhunter -y
     clear
     rkhunter -c --vl --sk
     echo "Logfile unter: /var/log/rkhunter.log"
     echo "Logfile unter: /var/log/rkhunter.log" >> /tmp/harderscript.log
     break
     ;;
     [nN][oO]|[nN])
     clear
     echo "rkhunter scan wird nicht ausgeführt!"
     echo "skip rkhunter scan" >> /tmp/harderscript.log
     break
     ;;
     *)
     echo "Invalid input..."
     ;;
     esac
     done
clearandsleep
#Anlegen eines neuen Nutzers, Eintragung in sudoers Datei
echo "Es wird empfohlen einen neuen Nutzer mit sudo-Rechten anzulegen!"
clearandsleep
while true
do
read -r -p "Soll ein neuer Benutzer mit Sudo-Rechten angelegt werden? [Y/N]" input
case $input in
     [yY][eE][sS]|[yY])
     echo "Bitte geben Sie den Nutzernamen ein:"
     read username
     sudo adduser $username --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
     echo ""$username":password" | sudo chpasswd
     usermod -aG sudo $username
     clearandsleep
     userverify=$(cat /etc/group | grep $username >/dev/null && echo JA || echo NEIN)
     if [ $userverify = "JA" ]
     then
      echo "Es wurde ein neuer Nutzer " $username "angelegt."
      echo "Es wurde ein neuer Nutzer " $username "angelegt." >> /tmp/harderscript.log
      clearandsleep
      echo "Es wird empfohlen sich als Nutzer" $username "anzumelden und das root Konto mit dem Befehl sudo passwd -l root zu deaktivieren!";
      echo " Wir sind nun fertig. Ein Logfile befindet sich unter /tmp/harderscript.log"
      echo "Ende" >> /tmp/harderscript.log
     else
      echo "Kann Nutzer " $username "nicht in /etc/groups finden - bitte haendisch Prüfen!"
      echo "Kann Nutzer " $username "nicht in /etc/groups finden - bitte haendisch Prüfen!" >> /tmp/harderscript.log
      echo "Ende" >> /tmp/harderscript.log
  fi
break
;;
     [nN][oO]|[nN])
echo "Es wurde kein neuer Nutzer angelegt...Dann sind wir hier fertig!"
echo "Es wurde kein neuer Nutzer angelegt" >> /tmp/harderscript.log
echo "Ende" >> /tmp/harderscript.log
break
;;
*)
echo "Invalid input..."
;;
esac
done
clear
apt clean
apt autoremove -y
clearandsleep
echo "#######################################################################################"
echo ""
echo "Es wird dringend empfohlen die SSH authtifizierung via PUB-Key-Verfahren einzustellen!"
echo ""
echo "#######################################################################################"
clearandsleep
echo "##########################################################################################################"
echo ""
echo "Logsfiles befinden sich unter: /tmp/harderscript.log"
echo ""
echo "Nach dem lesen der Logfiles bitte das System neustarten um die neue Konfiguration abschließend zu laden!"
echo ""
echo "#########################################################################################################"

#english part
else
  if [ $nutzer = "root" ]
  then
    echo "${GREEN}Superuser login sucessfull.${NOCOLOR}";
    echo "creating logfile...";
    touch /tmp/harderscript.log
    echo "################################" >> /tmp/harderscript.log
    date >> /tmp/harderscript.log
    echo "root started script" >> /tmp/harderscript.log
  else
    echo "Run this script as root user!"
    exit 0
  fi
  clearandsleep
  #Testen der Internetverbindung
  inet=$(ping -c3 1.1.1.1 | grep -i 0% >/dev/null && echo JA || echo Nein)
  if [ $inet = "JA" ]
  then
    ping -c3 1.1.1.1 | grep -i 0% >> /tmp/harderscript.log
    echo "${GREEN}Internetconnection established. Ping successfull${NOCOLOR}"
    clearandsleep
    #Installation von Updates sowie von Paketen
    echo "Starting updates..."
    sleep 2s
    clear
    apt update && apt upgrade -y
    echo "${GREEN}Updates applied successfully${NOCOLOR}"
    clearandsleep
    paket
  else
    echo "${RED}Bad or no internetconnection${NOCOLOR}"
    echo "Bad or no internetconnection" >> /tmp/harderscript.log
    clearandsleep
    echo "We will try to go on..."
    apt update && apt upgrade -y
    clearandsleep
    paket
  fi
  #Prüfung ob Programme installiert wurden
  echo "Testing if programms were installed sucessfully...${RED}!(unstable)${NOCOLOR}"
  fail2ban=`type -p fail2ban-server`
  if [ ! -f "$fail2ban" ]; then
    echo "${RED}Fail2ban cloud be missing..${NOCOLOR}"
  else
    echo "${GREEN}Fail2ban ready!${NOCOLOR}"
  fi
  clearandsleep
  iptablesper=$(apt install iptables-persistent | grep -i "newest" >/dev/null && echo JA || echo NEIN)
  if [ $iptablesper = "JA" ]
  then
    echo "${GREEN}iptables-persistent ready!${NOCOLOR}"
    echo "iptables ready" >> /tmp/harderscript.log
  else
    echo "${RED}iptables-persistent missing..${NOCOLOR}"
    echo "iptables missing?" >> /tmp/harderscript.log
  fi
  clearandsleep
  sudo=`type -p sudo`
  if [ ! -f "$sudo" ]; then
    echo "${RED}sudo missing..${NOCOLOR}Starting installation"
    apt install sudo -y
    echo "sudo installed" >> /tmp/harderscript
  else
    echo "sudo ready!"
  fi
  clearandsleep
  #Zusätzliche Installation von Paketen
  y=1
  i=0
  while [ $y = 1 ]
  do
  clearandsleep
  echo "Do you want to install more programms/packages? (iftop,screen) [Y/N]"
  read package
  if [ $package = "N" ] || [ $package = "n" ]
  then
    clear
    if [ $i = 0 ]
    then
      echo "No additional programm will be installed."
      clearandsleep
    else
      echo "No additional programms will be installed.."
      clearandsleep
    fi
    y=2
  else
    clear
    i=$((i + 1 ))
    echo "Please enter the packagename:" $i
    read packagename
    #echo $packagename | cut -d ',' -f1-*
    echo "Package" $packagename "will be installed"
    apt install $packagename -y
    echo "additional package" $packagename >> /tmp/harderscript.log
    clearandsleep
    echo "Testing if " $packagename "is ready...(!unstable!)"
    varpackage=`type -p $packagename`
    if [ ! -f "$packagename" ]; then
      echo $packagename " missing.."
      clearandsleep
    else
      echo $packagename " ready!"
      clearandsleep
    fi
  fi
  done
  #SSH root login deaktivieren
  echo "Trying to find sshd_config...."
  path=$(find /etc -name sshd_config)
  echo $path
  while true
  do
   read -r -p "Is that the correct path? [Y/n] " input

   case $input in
       [yY][eE][sS]|[yY])
   echo "Forbid Root Login via SSH"
   sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' $path
   echo "Forbid SSH Rootlogin" >> /tmp/harderscript.log
   break
   ;;
       [nN][oO]|[nN])
   clear
   echo "${RED}Please try manualy to disable Rootlogin via SSH in the SSHD_CONFIG -File${NOCOLOR}"
   sleep 2s
   echo "SSH Rootlogin still allowed" >> /tmp/harderscript.log
   break
          ;;
       *)
   echo "Invalid input..."
   ;;
   esac
  done
  clearandsleep
  echo "Attention! This banner can be used for SSH-login!"
  clearandsleep
  echo "                                                                   #####
                                                                 #######
                    @                                            ##O#O##
   ######          @@#                                           #VVVVV#
     ##             #                                          ##  VVV  ##
     ##         @@@   ### ####   ###    ###  ##### ######     #          ##
     ##        @  @#   ###    ##  ##     ##    ###  ##       #            ##
     ##       @   @#   ##     ##  ##     ##      ###         #            ###
     ##          @@#   ##     ##  ##     ##      ###        QQ#           ##Q
     ##       # @@#    ##     ##  ##     ##     ## ##     QQQQQQ#       #QQQQQQ
     ##      ## @@# #  ##     ##  ###   ###    ##   ##    QQQQQQQ#     #QQQQQQQ
   ############  ###  ####   ####   #### ### ##### ######   QQQQQ#######QQQQQ

      ********************************************************************
      *                                                                  *
      * This system is for the use of authorized users only.  Usage of   *
      * this system may be monitored and recorded by system personnel.   *
      *                                                                  *
      * Anyone using this system expressly consents to such monitoring   *
      * and is advised that if such monitoring reveals possible          *
      * evidence of criminal activity, system personnel may provide the  *
      * evidence from such monitoring to law enforcement officials.      *
      *                                                                  *
      ********************************************************************"
  sleep 2s
  clearandsleep
  while true
  do
    read -r -p "Do you want to use this for SSH-login? [Y/n] " input
    case $input in
          [yY][eE][sS]|[yY])
          echo "Banner /etc/issue.net" >> $path
          echo "                                                                       #####
                                                                      #######
                         @                                            ##O#O##
        ######          @@#                                           #VVVVV#
          ##             #                                          ##  VVV  ##
          ##         @@@   ### ####   ###    ###  ##### ######     #          ##
          ##        @  @#   ###    ##  ##     ##    ###  ##       #            ##
          ##       @   @#   ##     ##  ##     ##      ###         #            ###
          ##          @@#   ##     ##  ##     ##      ###        QQ#           ##Q
          ##       # @@#    ##     ##  ##     ##     ## ##     QQQQQQ#       #QQQQQQ
          ##      ## @@# #  ##     ##  ###   ###    ##   ##    QQQQQQQ#     #QQQQQQQ
        ############  ###  ####   ####   #### ### ##### ######   QQQQQ#######QQQQQ

           ********************************************************************
           *                                                                  *
           * This system is for the use of authorized users only.  Usage of   *
           * this system may be monitored and recorded by system personnel.   *
           *                                                                  *
           * Anyone using this system expressly consents to such monitoring   *
           * and is advised that if such monitoring reveals possible          *
           * evidence of criminal activity, system personnel may provide the  *
           * evidence from such monitoring to law enforcement officials.      *
           *                                                                  *
           ********************************************************************" >> /etc/issue.net
           echo "Setup SSH banner!" >> /tmp/harderscript.log
           break
           ;;
           [nN][oO]|[nN])
           echo "Didnt setup banner!"
           echo "Didnt setup banner!" >> /tmp/harderscript.log
           break
           ;;
           *)
           echo "Invalid input..."
           ;;
         esac
       done
      clearandsleep
  echo "Installation of dpkg-dev and setting some flags..."
  echo "Installation of dpkg-dev and setting some flags..." >> /tmp/harderscript.log
  apt install dpkg-dev -y
  dpkg-buildflags --get CFLAGS
  dpkg-buildflags --get LDFLAGS
  dpkg-buildflags --get CPPFLAGS
  clearandsleep
  while true
  do
  read -r -p "Should we scan the system for rootkits? !rkhunter will be installed! [Y/N]" input
  case $input in
       [yY][eE][sS]|[yY])
       apt install rkhunter -y
       clear
       rkhunter -c --vl --sk
       echo "Logfile unter: /var/log/rkhunter.log"
       echo "Logfile unter: /var/log/rkhunter.log" >> /tmp/harderscript.log
       break
       ;;
       [nN][oO]|[nN])
       clear
       echo "will not run rootkit search"
       echo "skip rkhunter scan" >> /tmp/harderscript.log
       break
       ;;
       *)
       echo "Invalid input..."
       ;;
   esac
  done
  clearandsleep
  #Anlegen eines neuen Nutzers, Eintragung in sudoers Datei
  echo "It is recommended to setup a new user with root privileges!"
  clearandsleep
  while true
  do
  read -r -p "Should we create a new user? [Y/n]" input
  case $input in
       [yY][eE][sS]|[yY])
       echo "Please enter the username:"
       read username
       sudo adduser $username --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
       echo ""$username":password" | sudo chpasswd
       usermod -aG sudo $username
       clearandsleep
       userverify=$(cat /etc/group | grep $username >/dev/null && echo JA || echo NEIN)
       if [ $userverify = "JA" ]
       then
        echo "Created new user " $username "."
        echo "Created new user " $username "." >> /tmp/harderscript.log
        clearandsleep
        echo "It is recommended to login as" $username " to disable the rootuser with the command: sudo passwd -l root";
        echo "Now we have finished. You can find a logfile under /tmp/harderscript.log"
        echo "Finish" >> /tmp/harderscript.log
       else
        echo "Can not find " $username " in /etc/groups - please take a look manually"
        echo "Can not find " $username " in /etc/groups - please take a look manually" >> /tmp/harderscript.log
        echo "Finish" >> /tmp/harderscript.log
    fi
  break
  ;;
       [nN][oO]|[nN])
  echo "No additional user was created...Looks like we have finished!"
  echo "No additional user was created" >> /tmp/harderscript.log
  echo "Finish" >> /tmp/harderscript.log
  break
  ;;
*)
echo "Invalid input..."
;;
esac
done
clear
apt clean
apt autoremove -y
clearandsleep
echo "######################################################################################"
echo ""
echo "It is recommended to set up SSH-authtification over PUB-key-system!"
echo ""
echo "######################################################################################"
clearandsleep
echo "######################################################################################"
echo ""
echo "Logs can be found under /tmp/harderscript.log"
echo ""
echo "Afer reading the logfile please reboot the system to load up all new configurations!"
echo ""
echo "######################################################################################"
fi
