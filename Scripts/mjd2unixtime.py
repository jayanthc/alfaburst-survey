#!/usr/bin/python

# mjd2unixtime.py

import sys
import ephem

mjd = float(sys.argv[1])

jd = mjd + 2400000.5
unixTime = (jd - 2440587.5) * 86400
print unixTime

