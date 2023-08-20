#!/bin/csh

set acro=$1 # Peru-CS-SPC
./scripts/gen-scripts.pl $acro

./compile1institucion.sh Yes Yes

#beep
printf '\a'
printf '\a'
