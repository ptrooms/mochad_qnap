#!/bin/bash
# SESSION=$USER
# see [https://bfocht.github.io/mochad/]


if [ "$1" == "??" ] || [ "x$1" == "x??" ] ; then 
	echo "	Dec	Ch	Home	Devc 	Hex	Function code"
	echo "	0 	M 	13 	0000 	0 	All Units Off"
	echo "	1 	E 	5 	0001 	1 	All Lights On"
	echo "	2 	C 	3 	0010 	2 	On"
	echo "	3 	K 	11 	0011 	3 	Off"
	echo "	4 	O 	15 	0100 	4 	Dim"
	echo "	5 	G 	7 	0101 	5 	Bright"
	echo "	6 	A 	1 	0110 	6 	All Lights Off"
	echo "	7 	I 	9 	0111 	7 	Extended Code"
	echo "	8 	N 	14 	1000 	8 	Hail Request"
	echo "	9 	F 	6 	1001 	9 	Hail Acknowledge"
	echo "	10 	D 	4 	1010 	A 	Preset Dim (1)"
	echo "	11 	L 	12 	1011 	B 	Preset Dim (2)"
	echo "	12 	P 	16 	1100 	C 	Extended Data transfer"
	echo "	13 	H 	8 	1101 	D 	Status On"
	echo "	14 	B 	2 	1110 	E 	Status Off"
	echo "	15 	J 	10 	1111 	F 	Status Request"
	echo " "
	echo " X10-Reception (5A-pl, 5B=macro, 5D=rf), x#data, x00=Adress, xHU " 
	echo " 1--> 5a 02 00 48 = 2databytes, addres:   House O & Unit 14 "
	echo " X10-Reception (5A-pl, 5B=macro, 5D=rf), x#data, x01=Function, xFunc" 
	echo " 2--> 5a 02 01 42 = 2 databytes, function House O  switch ON"
	echo " cm15a X10 O1;on;off --> PT 04 46; PT 06 42; PT 06 43" 
	echo " check: http://www.linuxha.com/USB/cm15a.html"
fi

if [ "$1" == "?c" ] || [ "x$1" == "xc?" ] ; then 
	echo "    Function         Binary   Hex"
	echo "    All Units Off     0000      0"
	echo "    All Lights On     0001      1"
	echo "    On                0010      2"
	echo "    Off               0011      3"
	echo "    Dim               0100      4"
	echo "    Bright            0101      5"
	echo "    All Lights Off    0110      6"
	echo "    Extended Code     0111      7"
	echo "    Hail Request      1000      8"
	echo "    Hail Acknowledge  1001      9"
	echo "    Pre-set Dim (1)   1010      A"
	echo "    Pre-set Dim (2)   1011      B"
	echo "    ExtendedData xfer 1100      C"
	echo "    Status On         1101      D"
	echo "    Status Off        1110      E"
	echo "    Status Request    1111      F"
	exit 1
fi

if [ "$1" == "?h" ] || [ "x$1" == "xh?" ] ; then 
	echo "Hous Code Device Hex"
	echo "  A    1   0110    6"
	echo "  B    2   1110    E"
	echo "  C    3   0010    2"
	echo "  D    4   1010    A"
	echo "  E    5   0001    1"
	echo "  F    6   1001    9"
	echo "  G    7   0101    5"
	echo "  H    8   1101    D"
	echo "  I    9   0111    7"
	echo "  J   10   1111    F"
	echo "  K   11   0011    3"
	echo "  L   12   1011    B"
	echo "  M   13   0000    0"
	echo "  N   14   1000    8"
	echo "  O   15   0100    4"
	echo "  P   16   1100    C"
	exit 1
fi

if [ "$1" == "?" ] || [ "x$1" == "x" ] ; then 
	echo "help proto: $0   ?c-odes ?h-adressing ??-both"
	echo "Module commands: $0"
	echo "  st-atus"
	echo "  pl ax [on|off | [dim|bright] 0..31 | xdim 0..255 ]"
	echo "  pl a [on|off|dim|bright|xdim|all_lights_on|all_lights_off|all_units_off]"
	echo "  rf a1 [on|off|dim|bright]"
	echo "  rftopl [ *-all | abc.. | 0-none]"
	echo "  rftorf number --> // repeatRF Change Rx code to Tx code"
	echo "  getstatus ax "
	echo " parms:"
	echo "    ALL_UNITS_OFF | ALL_LIGHTS_ON/OFF | ON|OFF "
	echo "    DIM|BRIGHT|XDIM"
	echo "    EXTENDED_CODE_1|2|3"
	echo "    HAIL_REQUEST|HAIL_ACK"
	echo "    UNUSED"
	echo "    STATUS_ON|OFF|REQUEST  (set internal table)"
	echo "  new: PT ab cd ef   (write packets to cma15a)"
	echo "  new: VER (version)" 
	echo "  New: OF json|normal|normalraw|normal (??)" 
	echo "    intrftopl      Set CM15A to internal rf to pl"
	echo "    extrftopl      Disable internal CM15A rftopl"
	echo "    help           brief help message for mochad"
	echo "--raw-data"
	echo "--> readme: /home/pafoxp/code-mochad/README"
	exit 1
fi
# use -N to switchoff commandline and return to prompt
if [ $1 == "st" ]; then echo "$@" | nc -N  mochad.pafo2.nl 1099 ;
else echo "$@" | nc -N mochad.pafo2.nl 1099 ;
fi
exit 0
