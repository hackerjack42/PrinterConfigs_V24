#!/bin/bash
ENABLE_RPI=0
ENABLE_TOOLHEAD=1
TOOLHEAD_TYPE=USB        # CAN or USB
ENABLE_PITB=0
ENABLE_MCU=0

USB_TOOLHEAD=usb-Klipper_rp2040_4D4A39333616543B-if00
CAN_TOOLHEAD=007e88aeda12
CAN_PITB=000000000000
CAN_MCU=f3b0bfc05fbb

CONFIG_RPI=~/config.RPI
CONFIG_TOOLHEAD=~/config.Nitehawk
CONFIG_PITB=~/config.PITB
CONFIG_MCU=~/config.MantaM8Pv1_1


sudo service klipper stop
cd ~/klipper
#git pull

if [ $ENABLE_RPI -eq 1 ]
then
    echo Build for \(RPI Host\) Enabled
    make clean KCONFIG_CONFIG=$CONFIG_RPI
    make olddefconfig KCONFIG_CONFIG=$CONFIG_RPI
    #make KCONFIG_CONFIG=$CONFIG_RPI
    make flash KCONFIG_CONFIG=$CONFIG_RPI
else
    echo Build for \(RPI Host\) Disabled
fi

if [ $ENABLE_TOOLHEAD -eq 1 ]
then
    echo Build for \(Toolhead\) Enabled
    make clean KCONFIG_CONFIG=$CONFIG_TOOLHEAD
    make olddefconfig KCONFIG_CONFIG=$CONFIG_TOOLHEAD
    make KCONFIG_CONFIG=$CONFIG_TOOLHEAD
    #python3 ~/katapult/scripts/flash_can.py -u $CAN_TOOLHEAD -f out/klipper.bin
    if [ $TOOLHEAD_TYPE == "CAN" ]
    then
        python3 ~/katapult/scripts/flash_can.py -i can0 -u $CAN_TOOLHEAD -f out/klipper.bin
    elif [ $TOOLHEAD_TYPE == "USB" ]
    then
        make flash KCONFIG_CONFIG=$CONFIG_TOOLHEAD FLASH_DEVICE=/dev/serial/by-id/$USB_TOOLHEAD
    fi
else
    echo Build for \(Toolhead\) Disabled
fi

if [ $ENABLE_PITB -eq 1 ]
then
    echo Build for \(PITB\) Enabled
    make clean KCONFIG_CONFIG=$CONFIG_PITB
    make olddefconfig KCONFIG_CONFIG=$CONFIG_PITB
    make KCONFIG_CONFIG=$CONFIG_PITB
    python3 ~/katapult/scripts/flash_can.py -u $CAN_PITB -f out/klipper.bin
else
    echo Build for \(PITB\) Disabled
fi

if [ $ENABLE_MCU -eq 1 ]
then
    echo Build for \(MCU\) Enabled
    make clean KCONFIG_CONFIG=$CONFIG_MCU
    make olddefconfig KCONFIG_CONFIG=$CONFIG_MCU
    make KCONFIG_CONFIG=$CONFIG_MCU
    python3 ~/katapult/scripts/flash_can.py -u $CAN_MCU -r
    sleep 1
    make flash FLASH_DEVICE=0483:df11 KCONFIG_CONFIG=$CONFIG_MCU
#    python3 ~/katapult/scripts/flash_can.py -d /dev/serial/by-id/usb-CanBoot_stm32f407xx_2A0036001147393532373434-if00 -f out/klipper.bin
else
    echo Build for \(MCU\) Disabled
fi

#~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0
~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0

sudo service klipper start
cd -
