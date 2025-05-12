#!/bin/bash

# Common path for all GPIO access
BASE_GPIO_PATH=/sys/class/gpio

# Assign names to GPIO pin numbers for each light
GREEN=26

# Assign names to states
ON="1"
OFF="0"

# Utility function to export a pin if not already exported
exportPin()
{
  if [ ! -e $BASE_GPIO_PATH/gpio$1 ]; then
    echo "$1" > $BASE_GPIO_PATH/export
  fi
}

# Utility function to set a pin as an output
setOutput()
{
 # echo "out" > $BASE_GPIO_PATH/gpio$1/direction
 pinctrl set $1 ip pu
}

setInput()
{
  echo "in" > $BASE_GPIO_PATH/gpio$1/direction
}
# Utility function to change state of a light
setLightState()
{
  echo $2 > $BASE_GPIO_PATH/gpio$1/value
}

getValue()
{
  #cat $BASE_GPIO_PATH/gpio$1/value
  pinctrl get $1
}
# Utility function to turn all lights off
allLightsOff()
{
  setLightState $RED $OFF
  setLightState $YELLOW $OFF
  setLightState $GREEN $OFF
}

# Ctrl-C handler for clean shutdown
shutdown()
{
  exit 0
}

trap shutdown SIGINT
#exportPin $GREEN

setOutput $GREEN

while [ 1 ]
do
  files=(*.mp3)
  for i in "${!files[@]}"; do
    j=$(( RANDOM % "${#files[@]}" ))
    [ "$i" -ne "$j" ] && {
      tmp="${files[i]}"
      files[i]="${files[j]}"
      files[j]="$tmp"
    }
  done
  state=$(getValue $GREEN | awk '{print $5}')
  if [[ "$state" == "lo" ]]; then
    echo $files
    mpg321 $files
  fi
done
