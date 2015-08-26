#! /bin/bash
mkdir /data/Survey/abc2
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
numactl -C 0-5 -l ABPipeline --config=/home/artemis/Survey/Config/Beam4_client.xml &> /data/Survey/abc2/log_pipeline0.dat &
pidp0=$!
numactl -C 6-11 -l ABPipeline --config=/home/artemis/Survey/Config/Beam5_client.xml &> /data/Survey/abc2/log_pipeline1.dat &
pidp1=$!
sleep 5
numactl -C 12-17 ABServer --config=/home/artemis/Survey/Config/Beam4_server.xml &> /data/Survey/abc2/log_server0.dat &
pids0=$!
numactl -C 18-23 ABServer --config=/home/artemis/Survey/Config/Beam5_server.xml &> /data/Survey/abc2/log_server1.dat &
pids1=$!
wait $pidp0
wait $pidp1
wait $pids0
wait $pids1
