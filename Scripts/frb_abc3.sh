#! /bin/bash
mkdir /data/Survey/Data
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
numactl -C 0-5 -l ABPipeline --config=/home/artemis/Survey/Config/Beam6_client.xml &> /data/Survey/Log/pipeline0.log &
pidp0=$!
sleep 5
numactl -C 12-17 ABServer --config=/home/artemis/Survey/Config/Beam6_server.xml &> /data/Survey/Log/server0.log &
pids0=$!
wait $pidp0
wait $pids0
