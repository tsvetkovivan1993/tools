#!/usr/bin/python3
import ipaddress
import os

def install_ipmitool():
    # Проверка ОС и установка IPMITOOL
    my_os = os.system("apt -v")
    if my_os == 0:
        os.system("apt update && apt install -y ipmitool")
    else:
        os.system("yum -y install ipmitool")

def configure_ipmi(ip, netmask, gw):
    os.system(f"ipmitool lan set 1 ipaddr {ip}")
    os.system(f"ipmitool lan set 1 netmask {netmask}")
    os.system(f"ipmitool lan set 1 defgw ipaddr {gw}")
    print("\nНастройки применены. Проверьте подключение к новому IP.")

# Проверка установки IPMITOOL
ipmitool = os.system("ipmitool chassis selftest")
if ipmitool != 0:
    print("ipmitool не установлен. Устанавливаем...")
    install_ipmitool()

# Выбор режима настройки
print("Выберите режим настройки:")
print("1: По умолчанию с маской /30")
print("2: Ввести IP, маску и шлюз вручную")
choice = input("\nВведите номер режима: ").strip()

if choice == '1':
    # Режим по умолчанию с маской /30
    print("\nВведите IP адрес сети (e.g. x.x.x.x): ")
    ipmi_source = input().strip()
    ipmi_source = str(ipaddress.IPv4Address(ipmi_source))
    
    network = ipaddress.IPv4Network(f"{ipmi_source}/30", strict=False)
    ipmi_ip = network.network_address + 2
    ipmi_gw = network.network_address + 1
    
    print(f"\nНастраиваем: IP = {ipmi_ip}, Маска = {network.netmask}, Шлюз = {ipmi_gw}")
    configure_ipmi(str(ipmi_ip), str(network.netmask), str(ipmi_gw))

elif choice == '2':
    # Кастомный режим
    print("\nВведите IP адрес IPMI: ")
    custom_ip = input().strip()
    
    print("\nВведите маску подсети: ")
    custom_mask = input().strip()
    
    print("\nВведите IP адрес шлюза: ")
    custom_gw = input().strip()
    
    try:
        # Проверяем корректность формата адресов
        custom_ip = str(ipaddress.IPv4Address(custom_ip))
        custom_gw = str(ipaddress.IPv4Address(custom_gw))
        ipaddress.IPv4Network(f"0.0.0.0/{custom_mask}")  # Проверка маски
        
        print(f"\nНастраиваем: IP = {custom_ip}, Маска = {custom_mask}, Шлюз = {custom_gw}")
        configure_ipmi(custom_ip, custom_mask, custom_gw)
    
    except ValueError as e:
        print(f"Ошибка в формате IP/маски/шлюза: {e}")

else:
    print("Некорректный выбор режима.")
