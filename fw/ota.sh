#!/bin/sh

mqtt_broker="mqtt.hvc.bonnee.me"

devname=$1
hostname=$1
if [ ! -z $2 ]; then
  hostname="$2"
fi

set -e
esphome compile "$devname.yaml"
set +e

mosquitto_pub -r -h "$mqtt_broker" -t "/$devname/esp/ota_mode" -m 'ON'

echo "waiting for ping from $hostname"
until ping -c1 "$hostname" > /dev/null 2>&1; do sleep 5; :; done &
trap "kill $!; mosquitto_pub -r -h $mqtt_broker -t "/$devname/esp/ota_mode" -m 'OFF'; echo \"exiting\"; exit 0" INT
wait $!
trap - INT

mosquitto_pub -r -h "$mqtt_broker" -t "/$devname/esp/ota_mode" -m 'OFF'

set -e
esphome upload "$devname.yaml" --device "$hostname"

mosquitto_pub -r -h "$mqtt_broker" -t "/$devname/esp/sleep_mode" -m 'ON'
echo "putting device to sleep"
sleep 10
mosquitto_pub -r -h "$mqtt_broker" -t "/$devname/esp/sleep_mode" -m 'OFF'

