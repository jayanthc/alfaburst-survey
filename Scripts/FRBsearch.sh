#!/bin/bash

# for cron
source /home/artemis/.bashrc

echo "----"
echo "FRBsearch.sh \"at-style date for termination\""
if [ $# == 1 ]; then
    at $1 -f /home/artemis/Survey/Scripts/killobs_SSH
fi
echo ALFABURST > /home/artemis/Survey/Flags/ALFABURST.FLAG
echo Starting survey on `date` >> /home/artemis/Survey/Log/Obs.log
function observe {
    ssh artemis@abc0 "/home/artemis/Survey/Scripts/frb_abc0.sh" & 
    pidabc0=$!
    ssh artemis@abc1 "/home/artemis/Survey/Scripts/frb_abc1.sh" & 
    pidabc1=$!
    ssh artemis@abc2 "/home/artemis/Survey/Scripts/frb_abc2.sh" & 
    pidabc2=$!
    ssh artemis@abc3 "/home/artemis/Survey/Scripts/frb_abc3.sh" & 
    pidabc3=$!
    echo Waiting for $pidabc0 $pidabc1 $pidabc2 $pidabc3
    wait $pidabc0
    wait $pidabc1
    wait $pidabc2
    wait $pidabc3
}

function checkFlag {
    Flag=$(cat $flagfile)
    while [ $Flag -eq 2 ]; do
	echo Station is busy
	sleep 60
	Flag=$(cat $flagfile)
    done
}

function endGracefully {
    echo "Stopping survey on:" `date`>> /home/artemis/Survey/Log/Obs.log
    echo "-" >> /home/artemis/Survey/Log/Obs.log
}

while [ -f /home/artemis/Survey/Flags/ALFABURST.FLAG ]; do
    echo ALFABURST is running
    echo "Clear to observe on:" `date`>> /home/artemis/Survey/Log/Obs.log
    date
    #echo "ALFABURST just launched on "`date`|/home/artemis/Survey/Scripts/ttytter -status=-
    observe
    echo Survey has stopped so try again
    #echo "ALFABURST just stopped on "`date`|/home/artemis/Survey/Scripts/ttytter -status=-
done
# Anything you call after here only happens at the end of a graceful exit
endGracefully

