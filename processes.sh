#!/bin/bash

MYPIDS=($(ps auxww | grep $1 | awk '{print $2; }'))
while true
do

	for pid in "${MYPIDS[@]}"
	do
		top -b -n 1 -p $pid | awk -v OFS="," '$1+0>0 { print strftime("%Y-%m-%d %H:%M:%S"), $1, $NF, $9, $10; fflush() }' >> procs.csv
	done
	sleep 1
done
