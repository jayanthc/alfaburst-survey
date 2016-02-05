#!/bin/bash

# PORT should be 16704 or 16705
PORT="$1"
tcpdump -i eth2 -B 10000000 -w `date +%Y%m%d%H%M%S`.pcap udp port $PORT

