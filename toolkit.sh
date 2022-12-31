#!/bin/bash

clear
exec 2>/dev/null

DEF='\033[0;39m'       #  ${DEF}
DGRAY='\033[1;30m'     #  ${DGRAY}
LRED='\033[1;31m'      #  ${LRED}
LGREEN='\033[1;32m'    #  ${LGREEN}
LYELLOW='\033[1;33m'   #  ${LYELLOW}
LBLUE='\033[1;34m'     #  ${LBLUE}
LMAGENTA='\033[1;35m'  #  ${LMAGENTA}
LCYAN='\033[1;36m'     #  ${LCYAN}
WHITE='\033[1;37m'     #  ${WHITE}

set -o pipefail

#### System test

# SYSTEM INFO
OS=$({ lsb_release -d|awk -F ':\t' '{print $2}' || cat /etc/centos-release || cat /etc/*release | grep -w NAME | awk -F= '{print $2}' | sed -s 's/"//g' ;})
if [[ -f /proc/user_beancounters ]]; then
    PLATFORM="VM OVZ"
elif [[ `cat /proc/cpuinfo  | grep -w hypervisor` ]]; then
    PLATFORM="VM KVM"
else
    PLATFORM="DEDIC"
fi
CPU_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)
MEM_TOTAL=$(( $(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }') / 1024 ))
SWAP=$(( $(cat /proc/meminfo | grep SwapTotal | awk '{ print $2 }') / 1024 ))
echo -ne "${LGREEN}System info:${DEF} "
echo -ne "$OS [${LCYAN}$PLATFORM${DEF}]    CPU: $CPU_COUNT    RAM: $MEM_TOTAL MB    SWAP: $SWAP MB\n"

# LOAD
WA=$(vmstat|tail -n1|awk '{print $16}')
LA1=$(cat /proc/loadavg |cut -d' ' -f1)
LA5=$(cat /proc/loadavg |cut -d' ' -f2)
LA15=$(cat /proc/loadavg |cut -d' ' -f3)
echo -ne "${LGREEN}Load: ${DEF}"
echo -ne "LA: $LA1 $LA5 $LA15    WA: $WA\n"

# DISK
DTOTAL=$(df -h / |tail -n1|awk '{print $2}')
DUSAGE=$(df -h / |tail -n1|awk '{print $3}')
DFREE=$(df -h / |tail -n1|awk '{print $4}')
echo -ne "${LGREEN}Disk: ${DEF}"
echo -ne "Total: $DTOTAL    Usage: $DUSAGE    "
if [[ `df -h | grep -w "/" | awk '{print $5}' | sed -s 's/%//g'` > 90 ]]; then
    echo -ne "${LRED}Free: $DFREE (<90%)${DEF}    "
else
    echo -ne "Free: $DFREE    "
fi

# INNODE
if [[ `df -i | grep -w "/" | awk '{print $5}' | sed -s 's/%//g'` > 90 ]]; then
    echo -ne "${LGREEN}Innode usage: ${DEF}${LRED}$(df -i / | awk '{print $5}' | tail -n1) (<90%)${DEF}\n"
else
    echo -ne "${LGREEN}Innode usage: ${DEF}$(df -i / | awk '{print $5}' | tail -n1)\n"
fi

# NUMFILE
if [[ -f /proc/user_beancounters ]]; then
    NUM_LIM=$(grep 'numfile' /proc/user_beancounters|awk '{print $5}')
    NUM_CUR=$(grep 'numfile' /proc/user_beancounters|awk '{print $3}')
    NUM_ERR=$(grep 'numfile' /proc/user_beancounters|awk '{print $NF}')
    echo -ne "${LGREEN}Numfile: ${DEF}"
    echo -ne "Limit: $NUM_LIM    Current: $NUM_CUR    Error: $NUM_ERR\n"
fi

# NETWORK
TCP_COUNT=$(ss -ant|grep -E 'ESTAB|SYN'|wc -l)
UDP_COUNT=$(ss -anu|wc -l)

rx1=`cat /sys/class/net/eth0/statistics/rx_bytes || cat /sys/devices/virtual/net/venet0/statistics/rx_bytes`
tx1=`cat /sys/class/net/eth0/statistics/tx_bytes || cat /sys/devices/virtual/net/venet0/statistics/tx_bytes`
sleep 1
rx2=`cat /sys/class/net/eth0/statistics/rx_bytes || cat /sys/devices/virtual/net/venet0/statistics/rx_bytes` && let rx=$rx2-$rx1 && let rx=$rx*8 && let rx=$rx/1024
tx2=`cat /sys/class/net/eth0/statistics/tx_bytes || cat /sys/devices/virtual/net/venet0/statistics/tx_bytes` && let tx=$tx2-$tx1 && let tx=$tx*8 && let tx=$tx/1024
NET_IN=$rx
NET_OUT=$tx
echo -ne "${LGREEN}Network: ${DEF}"
echo -ne "TCP: $TCP_COUNT UDP: ${UDP_COUNT}    IN: $NET_IN Kbit/sec OUT: $NET_OUT Kbit/sec\n"

# ISPmanager
# echo "ihttpd=$(pgrep ihttpd >/dev/null && echo Worked || echo -en ${LRED}No${DEF}\\n)"
CORE_VER=$(/usr/local/mgr5/bin/core -V)
ISP_VER=$(/usr/local/mgr5/bin/core ispmgr -V)
echo -ne "${LGREEN}ISPmanager: ${DEF}"
echo -ne "Core ver.: $CORE_VER   ISP ver.: $ISP_VER\n"

# MySQL
MYSQL_VER=$(mysql -V || echo -ne "${LRED}not installed${DEF}")
echo -ne "${LGREEN}MySQL: ${DEF}$MYSQL_VER\n"

exec 2>&1



### MENU ###

ISP_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n ISP menu:\n${DEF}"
    script_isp[0]='Назад'
    script_isp[1]='Подложить ключ ISPmanager5'
    script_isp[2]='Версия панели'
    script_isp[3]='Составить hosts из webdomain'
    script_isp[4]='ISPmanager upgrade'
    script_isp[5]='ISPmanager upgrade only ispmgr'
    script_isp[6]='Установить панель ISPmanager5'
    script_isp[7]='Получить список доменов'
    script_isp[8]='Chown на /var/www/$USER/data/www'

    for index in ${!script_isp[*]}; do
      printf "%4d: %s\n" $index "${script_isp[$index]}"
    done
  }

  while :
  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        /usr/local/mgr5/sbin/mgrctl -m ispmgr session.newkey username=root key=eu8quaiph2iZohthe6shaquaeyahloh2
        echo -ne "\nispmgr?func=auth&username=root&key=eu8quaiph2iZohthe6shaquaeyahloh2&checkcookie=noht\n"
        echo -ne "${LGREEN}Done${DEF}\n"
        ;;
      2)
        echo -ne "\n"
        echo -ne "Core: $(/usr/local/mgr5/bin/core -V)\n"
        echo -ne "ISP: $(/usr/local/mgr5/bin/core ispmgr -V)\n"
        ;;
      3)
        echo -ne "\n"
        echo "Перенос данных выполнен, проверить работу сайтов, не меняя записи ДНС, можно прописав на локальном ПК в файле hosts (C:\Windows\System32\drivers\etc\hosts) следующие данные:"
        # /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk -F'ipaddr=|name=| ' '{print $NF, $2, "www." $2}'
        for i in `/usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk -F'ipaddr=|name=| ' '{print $(NF-1)"::"$2}'`; do idn=$(echo $i|awk -F'::' '{print $2}'|xargs python2 -c 'import sys;print (sys.argv[1].decode("utf-8").encode("idna"))'); echo "`echo $i | awk -F'::' '{print $1}'` $idn www.$idn"; done
        echo -ne "\n"
        echo "FirstVDS: Подробнее на нашем сайте - https://firstvds.ru/technology/check-after-transfer"
        echo -ne "ISPserver: Подробнее на нашем сайте - https://ispserver.ru/help/proverka-dostupnosti-sayta-posle-perenosa\n\n"
        echo "Если все работает корректно, то можете сменить на серверах имен А-записи для доменов на ip нового сервера. Либо прописать у регистратора наши сервера имен:"
       echo -ne "FirstVDS:\nns1.firstvds.ru.\nns2.firstvds.ru.\n"
       echo -ne "ISPserver:\nns1.ispvds.com.\nns2.ispvds.com.\n"
        ;;
      4)
        read -r -p "You are making a mistake (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
            then
                /usr/local/mgr5/sbin/pkgupgrade.sh coremanager
                echo -ne "${LGREEN}Done${DEF}\n"
            else
                echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      5)
        read -r -p "You are making a mistake (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            /usr/local/mgr5/sbin/pkgupgrade.sh ispmanager-lite-common
            echo -ne "${LGREEN}Done${DEF}\n"
        else
            echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      6)
        read -r -p "You are making a mistake (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            read -r -p "Auto install ISPmanager beta (y/N)? " response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
                wget http://download.ispsystem.com/install.sh && sh install.sh --silent --ignore-hostname --release beta ispmanager-lite
                echo -ne "${LGREEN}Done${DEF}\n"
            else
                wget http://download.ispsystem.com/install.sh && sh install.sh
                echo -ne "${LGREEN}Done${DEF}\n"
            fi
        else
          echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      7)
        echo -ne "\n"
        /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print $1}' | sed -s 's/name=//g'
        ;;
      8)
        read -r -p "Do you really want it? (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            find /var/www/*/data/www/ -maxdepth 1 -type d | awk -F'/' '{print "chown -R "$4":"$4 " /var/www/"$4"/data/www/"}' | uniq | sh
            echo -ne "${LGREEN}Done${DEF}\n"
        else
            echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
  done
  exit
}

BITRIX_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n BITRIX menu:\n${DEF}"
    script_bitrix[0]='Назад'
    script_bitrix[1]='Скачать admin.sh'
    script_bitrix[2]='Скачать default конфиг bitrix gt'
    script_bitrix[3]='Скачать pusti.php'
    script_bitrix[4]='Скачать скрипты для wildcard LE'
    script_bitrix[5]='Скачать restore.php'

    for index in ${!script_bitrix[*]}; do
      printf "%4d: %s\n" $index "${script_bitrix[$index]}"
    done
  }

  while :
  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/admin.sh && chmod +x admin.sh
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      2)
        wget http://rep.fvds.ru/cms/bitrixinstaller.tgz
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      3)
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/pusti.php
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      4)
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook.sh -O /opt/lew_dnsmgr_hook.sh && chmod +x /opt/lew_dnsmgr_hook.sh
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook_del.sh -O /opt/lew_dnsmgr_hook_del.sh && chmod +x /opt/lew_dnsmgr_hook_del.sh
        echo -ne "\nКоманда для выпуска (в скрипте надо сменить доступы и путь до лога):\n"
        echo -ne "certbot certonly --manual --manual-public-ip-logging-ok --preferred-challenges=dns -d *.example.com -d example.com --manual-auth-hook /opt/lew_dnsmgr_hook.sh --manual-cleanup-hook /opt/lew_dnsmgr_hook_del.sh --dry-run\n"
        ;;
      5)
        wget http://www.1c-bitrix.ru/download/scripts/restore.php
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
  done
  exit
}


SCRIPTS_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n SCRIPTS menu:\n${DEF}"
    script_scripts[0]='Назад'
    script_scripts[1]='Скачать backup.sh'
    script_scripts[2]='Скачать resell5.sh'
    script_scripts[3]='Скачать BootUtil.zip'
    script_scripts[4]='Скачать sum2.1.tgz'
    script_scripts[5]='Upload to notes'
    script_scripts[6]='Замена IP'
    script_scripts[7]='Download Docker-fixer'

    for index in ${!script_scripts[*]}; do
      printf "%4d: %s\n" $index "${script_scripts[$index]}"
    done
  }

  while :
  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        wget https://gitlab.hoztnode.net/admins/scripts/raw/master/backup.sh && chmod +x backup.sh
        echo "0 1 * * * /root/backup.sh 3 day 2>&1|logger"
        echo "0 1 * * 7 /root/backup.sh 2 week 2>&1|logger"
        echo "0 1 1 * * /root/backup.sh 2 month 2>&1|logger"
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      2)
        wget https://gitlab.hoztnode.net/admins/scripts/raw/master/resell5.sh
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      3)
        wget https://notes.fvds.ru/share/BootUtil.zip
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      4)
        wget https://notes.fvds.ru/share/sum2.1.tgz
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      5)
        bash <(wget --no-check-certificate -q -o /dev/null -O- https://notes.fvds.ru/notesupload.sh) ;;
      6)
        echo -ne "${LMAGENTA}Настройки сети и ihttpd нужно сменить вручную! И иметь бэкап.\nТребуется sqlite3.${DEF}\n"
        read -p "Source IP: " src_ip
        read -p "Destination IP: " dst_ip

        if [[ ! `echo $src_ip | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'` ]]; then echo -ne "${LRED}Incorrect IP${DEF}\n"; exit; fi
        if [[ ! `echo $dst_ip | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'` ]]; then echo -ne "${LRED}Incorrect IP${DEF}\n"; exit; fi

        echo "Команды, которые будут выполнены:"
        echo "find /etc/ -type f -exec sed -si \"s/$src_ip/$dst_ip/g\" {} \;"
        if [[ -d /var/named ]]; then
          echo "find /var/named/ -type f -exec sed -si \"s/$src_ip/$dst_ip/g\" {} \;"
        fi
        echo "sqlite3 /usr/local/mgr5/etc/ispmgr.db \"update webdomain_ipaddr set value='$dst_ip' where value='$src_ip'\""
        read -r -p "Do you really want it? (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            find /etc/ -type f -exec sed -si "s/$src_ip/$dst_ip/g" {} \;
            if [[ -d /var/named ]]; then
              find /var/named/ -type f -exec sed -si "s/$src_ip/$dst_ip/g" {} \;
            fi
            sqlite3 /usr/local/mgr5/etc/ispmgr.db "update webdomain_ipaddr set value='$dst_ip' where value='$src_ip'"
            echo -ne "${LGREEN}Done${DEF}\n"
        else
            echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      7)
        wget https://gitlab.hoztnode.net/admins/scripts/-/raw/master/docker_fixer.sh
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
  done
  exit
}

KEYS_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n SCRIPTS menu:\n${DEF}"
    script_keys[0]='Назад'
    script_keys[1]='Есть GO'
    script_keys[2]='Добавить ключ мувалки 1-в-1'
    script_keys[3]='Добавить ключ банановоза'

    for index in ${!script_keys[*]}; do
      printf "%4d: %s\n" $index "${script_keys[$index]}"
    done
  }

  while :
  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        echo -ne "\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGsiUt5QA4nmdIf1pVUUu9d2ZUbyqliqlhoPwmZukcAz6uDHipCz8HUEW7FsHVG4i0tPv9OLFV+ZDqygoyriGOt6u1N/Jc+WG3xCukB+2DchFWFXq4uq37BFT8wifYEuWDxCMOuZzp4Ph5y+SqxUazleXGTCeVJxp1SsOPqnywuVyAgvYqEQU0O2vvdWhiqt/eousI0bIgajiVFxWJ505TLhriiwzbNNwBLOzSE+5V+toqRguI1WDsw/rA8n+mzvzuXUfXG55vABuGBEQU/k1zk7zysFit4EBe+D2pR2EiHqE11C/0V/Ohoe1vX91B4c2vKcuYnxAslbgXTVAM+hX3dYaTru3l8eqPy4XZ+3NC8ieDRfXnniU+CNo10agT66r8uEnQCy85VPsMimWR9cAclEnVf3GqHRnC5RCmDycn4VwKww9G+gQxWe4rCmzuROlj/aITpJFh75Wxd89t6Dd0hIPEpxz/nBg9FdK27Tpg8M/RBPmqlQs31+5d58355WUi9G+ysK1AQ2BWixepurkQBesmIGELun0yU6sVSYKFSSd7r0102Oy5btSjKEeJz9yrq0fbpTUiL4Y/sAgdgF1zqwCYbclGve47qXR2iF1shuR75IbiyHcYS33gelNqXeI1Gs5qTxvigeaWIV42+83tHAzuXgO7nPBOINXX1mISoQ== Support access key\n" >> /root/.ssh/authorized_keys
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      2)
        echo -ne "\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCai7ZIatSdotSieBF3os8SjtXsL7FWF81DQTgZFHGcMYGRN2mGKX3JhR9IZUQ7OBVJEZwC4QJPqxM2EAbIyB29XsZshyTPA9Ef6ZQPChwX6W1T9TEsf/3rWYBixyYyf+6cl87GvPuEL7NJBXWF6pnFgmpTDKCHJwuj3xssBpGW9GG3fSJBICBCAff3NaEqt30QH86nSkaLuzIWByEYDrPFBSb+uL7YWhw/73ixXx74i63JIUQ44pjJ1to0e5m/FBlFzg9c2H24sBPrDeM+jzxaC7SBh+sku5U8UH+pTh4Dnj97Ai3eG7OGp3nxdEzgSKH+CmLxHvR6gamRUgSMVdV support@move-linux\n" >> $HOME/.ssh/authorized_keys
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      3)
        echo -ne "\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlgKR+E60e6Y4XtDqw5pgA6W3pAaT0gSj0J1PgWmQMuHhkB1FB8SEW29P4ipzqquiG5+cUl3Ex+L9mCfaRFQknXbAodOUWWMqZ+5+i1uifXp/acLg8uW8CTxuE6AWSNZ0bR7w3nGuewxCfiGoRqD+7MRI7ow8PVJmxKeRWCbZwONCAcN7RnYYwxhq/tJS/2SQtVD8HDIxLAInJJwC6UiYEZaD3xsuABvuN3RadhdEXmf2rY08ngviw/hD8XDREFJS1vwNxaxqW0YHmmsUTZUhCKon91pRo18uflE3ulwyWIPHYTUFU5N1aKtQVGFcmGyRaTV1QKImLP12oWy886U0J admin@ftpmove\n" >> $HOME/.ssh/authorized_keys
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
  done
  exit
}

MAIN_MENU() {
    echo -ne "${LGREEN}\n Чего делаем?\n${DEF}"
    script[0]='Выход'
    script[1]='Бэкап ручной'
    script[2]='Бэкап by dn4g'
    script[3]=$(echo -ne "${LMAGENTA}Меню ISPmanager${DEF}")
    script[4]=$(echo -ne "${LMAGENTA}Меню Битрикс${DEF}")
    script[5]=$(echo -ne "${LMAGENTA}Keys${DEF}")
    script[6]='Парсер access.log'
    script[7]='Список соединений на 80/443 порты'
    script[8]='Отправить тестовое письмо'
    script[9]='Сбросить пароль MySQL'
    script[10]='Кто использует mailphp()'
    script[11]='Кто ест RAM?'
    script[12]='MTR тест'
    script[13]='Centos7 admin starter pack'
    script[14]='Проверить скорость инторнета'
    script[15]='Скачать Стасодамп'
    script[16]='mysqltuner.pl'
    script[17]='Проверить governor'
    script[18]='Strace на апачик'
    script[19]='Запустить python web-сервер'
    script[20]='Список юзер и пасс из mysql'
    script[21]=$(echo -ne "${LMAGENTA}Меню скриптов${DEF}")
    script[22]='Fix sysresccd locale'
    script[23]='SMART'


    for index in ${!script[*]}; do
      printf "%4d: %s\n" $index "${script[$index]}"
    done
}


while :
do
  MAIN_MENU
  read -r -p "Choose: " payload
  case $payload in
    0)
      clear && break ;;
    1)
      if [[ -d /root/support/`date '+%Y%m%d'` ]]; then \
      echo -ne "${LYELLOW}exist backup${DEF}: /root/support/`date '+%Y%m%d'`\\n"; else \
      mkdir -p /root/support/`date '+%Y%m%d'` && \
      rsync -a /etc /root/support/`date '+%Y%m%d'`; \
      iptables-save > /root/support/`date '+%Y%m%d'`/iptables.save; \
      # crontab -l > /root/support/`date '+%Y%m%d'`/crontab; \
      rsync -a /var/spool/cron /root/support/`date '+%Y%m%d'`; \
      rsync -a --exclude='var' --exclude='tmp' /usr/local/*mgr* /root/support/`date '+%Y%m%d'`; \
      rsync -a /var/www/httpd-cert /root/support/`date '+%Y%m%d'`; \
      echo -en "${LGREEN}Done${DEF} - /root/support/`date '+%Y%m%d'`\\n" ; fi
      ;;
    2)
      python2 <(wget -q -O- https://gitlab.hoztnode.net/admins/scripts/raw/master/messiah.py)
      ;;
    3)
      ISP_MENU ;;
    4)
      BITRIX_MENU ;;
    5)
      KEYS_MENU ;;
    6)
      read -r -p "Попарсим access-логи (y/N)?: " response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        DATE=$(LANG=en_us_88591; date +%d/%b/%Y);
        printf "\nТоп-10 наиболее активных IP-адресов:\n";
        grep "$DATE" /var/www/httpd-logs/*.access.log  | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10;
        printf "\n";

        printf "Что с сайтов было запрошено: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | awk '{print $1" "$7}' | sort | uniq -c | sort -rnk1 | head -n 10;
        printf "\n";

        printf "Запросы файла xmlrpc.php: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | grep "xmlrpc" | awk '{print $1" "$7}' | tr -d \" | uniq -c | sort -rnk1 | head
        printf "\n";

        printf "TOP-10 ботов: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | cut -d" " -f 12 | sort | uniq -c | sort -rnk1 | head -n 10
        printf "\n";
      fi
      ;;
    7)
      echo -ne "\n"
      netstat -an | grep -E '\:80|\:443'| awk '{print $5}' | grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | sort | uniq -c | sort -n
      ;;
    8)
      read -r -p '(echo "Subject:Support"; echo "Hello! Please, dont reply to this email.";) | sendmail -v ' email
      (echo "Subject:Support"; echo "Hello! Please, dont reply to this email.";) | sendmail -v $email
      ;;
    9)
      bash <(wget -q -O- https://gitlab.hoztnode.net/admins/scripts/raw/master/mysp.sh)
      ;;
    10)
      grep -R 'X-PHP-Originating' /var/spool/{exim,exim4}/input/| awk '{print $3}'|grep php|awk -F : '{print $2}'|sort|uniq -c
      ;;
    11)
      echo -ne "\n"
      ps axo rss,comm,pid \
      | awk '{ proc_list[$2]++; proc_list[$2 "," 1] += $1; } \
      END { for (proc in proc_list) { printf("%d\t%s\n", \
      proc_list[proc "," 1],proc); }}' | sort -n | tail -n 10 | sort -rn \
      | awk '{$1/=1024;printf "%.0fMB\t",$1}{print $2}'
      ;;
    12)
      read -r -p 'mtr -s 1500 -r -n -c 1000 -i 0.1 ' ip
      mtr -s 1000 -rbw -c 1000 -i 0.1 $ip
      ;;
    13)
      yum install net-tools screen strace -y
      ;;
    14)
      python <(wget -q -O- https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py)
      ;;
    15)
      wget -q https://gitlab.hoztnode.net/a.garin/wscripts/raw/master/mysql_dump.sh
      echo -ne "${LGREEN}Done${DEF}\\n"
      ;;
    16)
      read -r -p "Run or download (R/d)?: " response
      if [[ "$response" =~ ^([rR][uU][nN]|[rR]|"")+$ ]]; then
        perl <(wget -q -O- https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl) | grep -iv fail
      else
        echo -ne "\n\n$response\n"
        wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl && chmod +x mysqltuner.pl
      fi
      ;;
    17)
      cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
      ;;
    18)
      echo -ne "${LCYAN}exec:${DEF} strace -s 1024 -f \$(pidof httpd | sed 's/\([0-9]*\)/\-p \1/g')\n"
      strace -s 1024 -f $(pidof httpd | sed 's/\([0-9]*\)/\-p \1/g')
      ;;
    19)
      echo -ne "${LCYAN}exec:${DEF} python -m SimpleHTTPServer 5432\n"
      python -m SimpleHTTPServer 5432
      ;;
    20)
      echo -ne "\n"
      for i in `mysql -BNe "SELECT CONCAT_WS(',',user,host) FROM user" mysql`; do echo "-- user,host: $i"; mysql -BNe "SHOW GRANTS FOR '$(echo $i|awk -F',' '{print $1}')'@'$(echo $i|awk -F',' '{print $2}')'" | sed -s 's/$/;/g'; echo ; done
      ;;
    21)
      SCRIPTS_MENU ;;
    22)
      echo "en_US.UTF-8" >> /etc/locale.gen;
      locale-gen;
      ;;
    23) wget -q https://raw.githubusercontent.com/tsvetkovivan1993/tools/main/smart.sh && chmod +x smart.sh && ./smart.sh
      ;;
    *)
      echo -ne "${LRED}Unknown choose${DEF}\n" ;;
  esac
done

