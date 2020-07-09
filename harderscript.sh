#!/bin/bash
clear
echo -e "-------------------------------------Systeminformationen-------------------------------------"
echo -e "Hostname:\t\t"`hostname`
echo -e "uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo -e "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
echo -e "Kernel:\t\t\t"`uname -r`
echo -e "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo -e "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
echo -e "System Main IP:\t\t"`hostname -I`
echo -e "--------------------------------------------------------------------------------------------"
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
  echo "Versuche iptables-persistent zu installieren..."
  apt install  iptables-persistent -y
  clearandsleep
  echo "Updates und default Pakete sollten installiert sein" >> /tmp/harderscript.log
}
#Welcher Nutzer bin ich? Nur root darf ausführen
nutzer=$(whoami)
rot=root
language=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
echo $language
if [ $rot = "root" ]
then
  echo "Superuser erfolgreich angemeldet.";
  echo "Lege logfile an...";
  touch /tmp/harderscript.log
  echo "######################" >> /tmp/harderscript.log
  date >> /tmp/harderscript.log
  echo "root started script" >> /tmp/harderscript.log
  echo "Starte updates..."

else
  echo "Script muss als Root ausgeführt werden"
  exit 0
fi
clearandsleep
#Testen der Internetverbindung
inet=$(ping -c3 1.1.1.1 | grep -i 0% >/dev/null && echo JA || echo Nein)
if [ $inet = "JA" ]
then
  ping -c3 1.1.1.1 | grep -i 0% >> /tmp/harderscript.log
  echo "Internetverbindung vorhanden. Ping erfolgreich"
  clearandsleep
  #Installtion von Updates sowie von Paketen
  apt update && apt upgrade -y
  echo "Updates erfolgreich durch geführt!"
  clearandsleep
  paket
else
  echo "Schlechte oder keine Internetverbindung"
  echo "Schlechte oder keine Internetverbindung" >> /tmp/harderscript.log
  clearandsleep
  echo "Setzte Script fort..."
  apt update && apt upgrade -y
  clearandsleep
  paket
fi
#Prüfung ob Programme installiert wurden
echo "Prüfe ob Programme Ordnungsgemäß installiert wurden..."
fail2ban=`type -p fail2ban-server`
if [ ! -f "$fail2ban" ]; then
  echo "Fail2ban missing.."
else
  echo "Fail2ban vorhanden!"
fi
iptablesper=$(apt install iptables-persistent | grep -i "ist schon die neueste Version" >/dev/null && echo JA || echo NEIN)
if [ $iptablesper = "JA" ]
then
  echo "iptables-persistent vorhanden!"
  echo "iptables vorhanden" >> /tmp/harderscript.log
else
  echo "iptables-persistent missing.."
  echo "iptables fehlt?" >> /tmp/harderscript.log
fi
sudo=`type -p sudo`
if [ ! -f "$sudo" ]; then
  echo "sudo missing..Installiere"
  apt install sudo -y
  echo "sudo installiert" >> /tmp/harderscript
else
  echo "sudo vorhanden!"
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
 sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' $path
 echo "SSH Rootlogin verboten" >> /tmp/harderscript.log
 break
 ;;
     [nN][oO]|[nN])
 echo "SSH Rootlogin bitte haendisch deaktivieren in SSHD_CONFIG unter PermitRootLogin"
 echo "SSH Rootlogin weiterhin moeglich" >> /tmp/harderscript.log
 break
        ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done
clearandsleep
echo "Installiere dpkg-dev und setzte Flags..."
apt install dpkg-dev -y
dpkg-buildflags --get CFLAGS
dpkg-buildflags --get LDFLAGS
dpkg-buildflags --get CPPFLAGS
clearandsleep
#Anlegen eines neuen Nutzers, Eintragung in sudoers Datei
echo "Es wird empfohlen einen neuen Nutzer mit sudo-Rechten anzulegen!"
clearandsleep
read -r -p "Soll ein neuer Benutzer mit Sudo-Rechten angelegt werden? [Y/n]" input
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
     echo " Wir sind nun fertig. Ein Logfile befindet sich unter /tmp/harderscript.log :)"
     else
    echo "Kann Nutzer " $username "nicht in /etc/groups finden - bitte haendisch Prüfen!"
    echo "Kann Nutzer " $username "nicht in /etc/groups finden - bitte haendisch Prüfen!" >> /tmp/harderscript.log
  fi
break
;;
     [nN][oO]|[nN])
echo "Es wurde kein neuer Nutzer angelegt...Dann sind wir hier fertig!"
echo "Es wurde kein neuer Nutzer angelegt" >> /tmp/harderscript.log
esac
