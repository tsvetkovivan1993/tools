#!/usr/bin/python3
import ipaddress
import os
ipmitool=os.system("ipmitool chassis selftest")

if ipmitool == 0:
    print ("\nipmitool ustanovlen")
else:
# Проверка ОС и установка IPMITOOL
    print ("\nipmitool do not ustanovlen.")
    my_os = os.system("apt -v")
    if my_os == 0:
        os.system("apt update && apt install -y ipmitool")
    else:
        os.system("yum -y install ipmitool")
    
# Ввод брокаст-айпишника
print("\ntype /30 (Tolko IP!) IPMI: ")
ipmi_source=input()
ipmi_source=ipmi_source.strip()
ipmi_source=format(ipaddress.IPv4Address(ipmi_source))

# считаем айпишник и гейт
ipmi_ip=ipaddress.IPv4Address(ipmi_source) + 2
ipmi_gw=ipaddress.IPv4Address(ipmi_source) + 1

# проверяем и прожимаем
print("\nif vse norm:")
print ("\nnetwork: " + ipmi_source + "/30")
print ("\nGW: " + str(ipmi_gw))
print("\nIP: " + str(ipmi_ip))
print("\nplease najmi jubya button then here we go")
input()

os.system("ipmitool lan set 1 ipaddr "+ str(ipmi_ip))
os.system("ipmitool lan set 1 netmask 255.255.255.252")
os.system("ipmitool lan set 1 defgw ipaddr "+ str(ipmi_gw ))

# проверяем пинг до нового IP в течение минуты

print ("\nAll nastroyki done.\n Just podojdi odna minuta when it zapinjetsya")

ipmi_ping=os.system("ping -c 1 -w 60 " + str(ipmi_ip))

if ipmi_ping==0:
    print ("\neverything is done, you prekrasen")
else:
    print ("\nshoto-to going wrong, try Cold Reset or what do you hochesh")

# советуем, как прожать новый адрес в DCI
    
print("\nty could set new IPMI srazy v DCI, but smeni ID your dedic\n /usr/local/mgr5/sbin/mgrctl -m dcimgr server.connection elid=ID su=admin\n /usr/local/mgr5/sbin/mgrctl -m dcimgr server.connection.edit elid=ID_IPMI ip=" + str(ipmi_ip) + " sok=ok su=admin")
