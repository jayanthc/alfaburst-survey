#! /bin/bash

echo ============================
date
echo ============================
redis-cli -h serendip6 hgetall SCRAM:PNT | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}'
#echo ============================
redis-cli -h serendip6 hgetall SCRAM:AGC | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}' 
#echo ============================
redis-cli -h serendip6 hgetall SCRAM:ALFASHM | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}' 
#echo ============================
redis-cli -h serendip6 hgetall SCRAM:TT | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}' 
#echo ============================
redis-cli -h serendip6 hgetall SCRAM:IF1 | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}' 
#echo ============================
redis-cli -h serendip6 hgetall SCRAM:IF2 | awk 'NR%2==1 {printf("%s ",$1)} NR%2==0 {print $1}' 

