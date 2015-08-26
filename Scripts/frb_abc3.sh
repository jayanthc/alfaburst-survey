#! /bin/bash
mkdir /data/Survey/abc3
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
/home/artemis/Survey/Scripts/killobs
numactl -C 0-5 -l ABPipeline --config=/home/artemis/Survey/Config/Beam6_client.xml &> /data/Survey/abc3/log_pipeline0.dat &
pidp0=$!
sleep 5
numactl -C 12-17 ABServer --config=/home/artemis/Survey/Config/Beam6_server.xml &> /data/Survey/abc3/log_server0.dat &
pids0=$!
wait $pidp0
wait $pids0
