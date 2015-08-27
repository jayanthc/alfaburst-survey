#!/usr/bin/python

# mjd2lst.py

import sys
import ephem

mjd = float(sys.argv[1])

arecibo = ephem.Observer()
arecibo.lon = "-66:45.185"
arecibo.date = mjd - 15019.5
# convert MJD to LST and extract %H:%M:%S (no trailing decimals)
LST = str(arecibo.sidereal_time())[:-3]
print LST

