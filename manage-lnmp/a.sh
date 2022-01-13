#!/bin/bash
Color_Text()
{
  echo -e " \e[1;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}
Echo_pink()
{
  echo $(Color_Text "$1" "35")
}
Echo_Red "red"
Echo_Green "green"
Echo_Yellow "yellow"
Echo_Blue "blue"
Echo_pink "pink"

