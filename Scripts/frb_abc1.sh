#! /bin/bash
mkdir /data/Survey/Data
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
numactl -C 0-5 -l ABPipeline --config=/home/artemis/Survey/Config/Beam2_client.xml &> /data/Survey/Log/pipeline0.log &
pidp0=$!
numactl -C 6-11 -l ABPipeline --config=/home/artemis/Survey/Config/Beam3_client.xml &> /data/Survey/Log/pipeline1.log &
pidp1=$!
sleep 5
numactl -C 12-17 ABServer --config=/home/artemis/Survey/Config/Beam2_server.xml &> /data/Survey/Log/server0.log &
pids0=$!
numactl -C 18-23 ABServer --config=/home/artemis/Survey/Config/Beam3_server.xml &> /data/Survey/Log/server1.log &
pids1=$!
wait $pidp0
wait $pidp1
wait $pids0
wait $pids1
