#!/bin/bash
declare -a FILENAMES
declare -a PIDS

#
# collect list of pids from the pgrep
#  generate list of filenames like "Executable-PID"
#   generate gnuplot files with .memplot and .cpuplot extentions for each pid
#  collect stats for each pid
#
# while running or after ctrl+c, use gnuplot *plot in the directory where the plot and log files are
# view graphs with image viewer

main() {
	MYPID="${BASHPID}"
	while true
	do
		unset PIDS
		unset FILENAMES
		unset COMMANDS
		PIDS=($( pgrep -f $1 | grep -v "$MYPID"  ))
		for (( i = 0 ; i < ${#PIDS[@]} ; i++ ))
		do
			FILENAMES[$i]=$(ps --no-header -p ${PIDS[$i]} -o pid -o comm \
			| awk '{ print $2 "-" $1; }')
			if [ ! -f "${FILENAMES[$i]}.memplot" ]
			then
				genPlotSpec $i
			fi
		done
		collectStats
		sleep 1
	done
}

collectStats() {
	for (( i = 0 ; i < ${#PIDS[@]} ; i++ ))
	do
		ps --no-header -p ${PIDS[$i]} -o vsz -o rss -o %cpu -o %mem \
		| awk '{ print strftime("%s"), $1, $2, $3, $4; fflush() }' \
		>> "${FILENAMES[$i]}.log"

	done
}

genPlotSpec() {
	i=$1
	COMMAND="$(ps --no-header -p ${PIDS[$i]} -o args )"
	IFS=""
	TITLE=$(echo $COMMAND | fmt -w 80)
	TITLESTR=$(echo $TITLE | sed 's/$/\\n/' | tr -d '\n')
	unset IFS
	memPlotSpec $TITLESTR
	cpuPlotSpec $TITLESTR
}

memPlotSpec() {
cat >"${FILENAMES[$i]}.memplot" <<EOL
set title "$TITLESTR"
set term png small size 800,600
set output "${FILENAMES[$i]}-mem.png"
set ylabel "RSS"
set y2label "VSZ"
set timefmt '%s'
set xdata time
set format x '%T'
set ytics nomirror
set y2tics nomirror in
set yrange [0:*]
set y2range [0:*]

plot "${FILENAMES[$i]}.log" using 1:3 with lines axes x1y1 title "RSS", "${FILENAMES[$i]}.log" using 1:2 with lines axes x1y2 title "VSZ"
EOL
}

cpuPlotSpec() {
cat >"${FILENAMES[$i]}.cpuplot" <<EOL
unset y2label
unset y2tics
unset y2range
set title "$TITLESTR"
set term png small size 800,600
set output "${FILENAMES[$i]}-cpu.png"
set ylabel "%"

set timefmt '%s'
set xdata time
set format x '%T'

set yrange [0:*]
set offsets graph 0, 0, 0.05, 0.05

plot "${FILENAMES[$i]}.log" using 1:4 with lines title "%CPU", "${FILENAMES[$i]}.log" using 1:5 with lines title "%MEM"
EOL
}

if [[ $1 == "" ]]
then
	echo "Usage:"
	echo "$0 <pattern for pgrep>"
	echo "Example:"
        echo "$0 'commCem|commCs|commOms'"
	echo "$0 USL"
	exit
fi

main $1
