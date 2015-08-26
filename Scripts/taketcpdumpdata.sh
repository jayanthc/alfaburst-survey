#!/bin/bash

tcpdump -i eth2 -B 10000000 -w `date +%Y%m%d%H%M%S`.pcap udp port 16704

