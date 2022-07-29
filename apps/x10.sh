#!/bin/bash
# SESSION=$USER
# see [https://bfocht.github.io/mochad/]


if [ "$1" == "?" ] || [ "x$1" == "x" ] ; then 
	echo "commands: $0"
	echo "  st-atus"
	echo "  pl ax [on|off | [dim|bright] 0..31 | xdim 0..255 ]"
	echo "  pl a [on|off|dim|bright|xdim|all_lights_on|all_lights_off|all_units_off]"
	echo "  rf a1 [on|off|dim|bright]"
	echo "  rftopl [ *-all | abbc.. | 0-none]"
	echo "--raw-data"
	echo "--> readme: /home/pafoxp/code-mochad/README"
	exit 1
fi
# use -N to switchoff commandline and return to prompt
if [ $1 == "st" ]; then echo "$@" | nc -N  mochad.pafo2.nl 1099 ;
else echo "$@" | nc -N mochad.pafo2.nl 1099 ;
fi
exit 0
