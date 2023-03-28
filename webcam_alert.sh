#!/bin/bash

# Shell script to create a binary sensor in Home Assistant via MQTT which you can trigger via udev rules.

# Create a udev rule with the following name and contents, changing the Vendor and Product to match the output of lsusb | grep -i cam
# /etc/udev/rules.d/80-logitech-webcam-connect.rules
# ACTION=="add"    KERNEL=="video0" SUBSYSTEM=="video4linux" SUBSYSTEMS=="usb" ATTRS{idVendor}=="046d", ATTRS{idProduct}=="082c",  RUN+="/home/me/bin/webcam_alert/webcam_alert.sh connect"
# ACTION=="remove" KERNEL=="video0" SUBSYSTEM=="video4linux" SUBSYSTEMS=="usb" ATTRS{idVendor}=="046d", ATTRS{idProduct}=="082c",  RUN+="/home/me/bin/webcam_alert/webcam_alert.sh disconnect"

# Also, define the following three variables in a file named ../files/.env: MQTT_BROKER_HOST MQTT_USERNAME MQTT_PASSWORD

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

echo "$(date '+%Y-%m-%d %H:%M:%S') ${1}" >> ../../logs/webcam.log
source ../files/.env
UNIQUE_ID="$(hostname)_webcam_connection"
MQTT_CONFIGURATION_TOPIC="homeassistant/binary_sensor/${UNIQUE_ID}/config"
MQTT_STATE_TOPIC="homeassistant/binary_sensor/${UNIQUE_ID}/state"

configuration_payload="{
  \"name\": \"webcam\",
  \"unique_id\": \"${UNIQUE_ID}\",
  \"state_topic\": \"${MQTT_STATE_TOPIC}\"
}"

configuration_payload=$(echo $configuration_payload | jq)

mosquitto_pub -h "${MQTT_BROKER_HOST}" -P "${MQTT_PASSWORD}" -u "${MQTT_USERNAME}" -r -t "${MQTT_CONFIGURATION_TOPIC}" -m "${configuration_payload}" &

if [ "$1" = 'connect' ];
then
   status_payload='ON'
else
   status_payload='OFF'
fi

mosquitto_pub -h "${MQTT_BROKER_HOST}" -P "${MQTT_PASSWORD}" -u "${MQTT_USERNAME}" -r -t "${MQTT_STATE_TOPIC}" -m "${status_payload}" &



