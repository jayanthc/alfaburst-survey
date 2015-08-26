#!/usr/bin/python

# Plots the ALFA centre beam using the given co-ordinates, a circle denoting
# the centres of the six outer beams, and the locations of souces provided in
# the file 'sources'

import sys
import math
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap


def texInit(fontsize):
    # set plotting font properties
    font = {"family" : "serif",
            "weight" : "regular",
            "size"   : fontsize}
    plt.rc("font", **font)
    # force matplotlib to use Type 1 fonts instead of Type 3
    matplotlib.rcParams["ps.useafm"] = True
    matplotlib.rcParams["pdf.use14corefonts"] = True
    matplotlib.rcParams["text.usetex"] = True


def hhmm2deg(hh, mm):
    return int(hh) * degPerHour + ((float(mm) / 60) * degPerHour)


def ddmm2deg(ddmm):
    fDec = float(ddmm)
    return math.modf(fDec / 100)[1]                                           \
            + ((math.modf(fDec / 100)[0] * 100) / 60.0)


def plotBeams(pntRA, pntDec):
    # plot the beam centre
    #plt.plot(pntRA, pntDec, "rx")
    sky.plot(pntRA, pntDec, "rx")
    '''
    # plot the centre beam, up to HWHM on all sides
    beam = plt.Circle((pntRA, pntDec), hwhm, color="r", fill=False)
    fig = plt.gcf()
    fig.gca().add_artist(beam)
    # plot the maximum extent of the outer beams
    outerBeams = plt.Circle((pntRA, pntDec), r + hwhm, color="g", fill=False)
    fig.gca().add_artist(outerBeams)
    '''


#texInit(16)

# constants
# HWHM of the centre beam
hwhm = 1.775        # arcmin
# distance between the beam centre of the ALFA centre beam and the beam centre
# of an outer beam
r = 5.92            # arcmin
# degrees per hour
degPerHour = 15
# arcmin in degrees
arcmin2degFactor = 1.0 / 60
# convert arcmin values to degrees
hwhm *= arcmin2degFactor
r *= arcmin2degFactor

# pointing of the centre beam
#pntRA = float(sys.argv[1]) * degPerHour
#pntDec = float(sys.argv[2])

## 22:10
#pntRA1 = 18.6589730281 * degPerHour
#pntDec1 = 27.7909414941
#plotBeams(pntRA1, pntDec1)

# 22:15
pntRA = 19.2225166779 * degPerHour
pntRA -= 180
pntRA = -pntRA
print pntRA
pntDec = 9.0792778401

sky = Basemap(llcrnrlon=-160, llcrnrlat=5, urcrnrlon=-60, urcrnrlat=30,       \
        rsphere=(6378137.0, 6356752.3142), resolution="l", projection="merc", \
        lat_0=pntDec, lon_0=pntRA)

#plotBeams(pntRA, pntDec)
x, y = sky(pntRA, pntDec)
sky.plot(x, y, "go")

# 22:20
pntRA1 = 19.4562500074 * degPerHour
pntRA1 -= 180
pntRA1 = -pntRA1
print pntRA1
pntDec1 = 21.8061944871
#plotBeams(pntRA1, pntDec1)

x, y = sky(pntRA1, pntDec1)
sky.plot(x, y, "go")

# draw line between two pointings
#plt.plot([pntRA, pntRA1], [pntDec, pntDec1], color="k", linestyle=":")
sky.drawgreatcircle(pntRA, pntDec, pntRA1, pntDec1, color="g")
#sky.drawcoastlines()
#sky.fillcontinents()

'''
# 22:25
pntRA = 19.4562500074 * degPerHour
pntDec = 21.8061944871
plotBeams(pntRA, pntDec)

# 22:30
pntRA = 19.5318611179 * degPerHour
pntDec = 21.8062222606
plotBeams(pntRA, pntDec)

# 22:35
pntRA = 19.4628055628 * degPerHour
pntDec = 21.9248889311
plotBeams(pntRA, pntDec)
'''

# read the source list
sources = np.loadtxt("sources", dtype=str)

delimIdx = 9
RA = np.zeros(len(sources))
dec = np.zeros(len(sources))
for i in range(len(sources)):
    source = sources[i]
    # convert the hhmm right ascension to degrees
    RA[i] = hhmm2deg(source[0:2], source[2:4])
    RA[i] -= 180
    RA[i] = -RA[i]
    print RA[i]
    # convert the ddmm declination to degrees
    if source[4] != "+" and source[4] != "-":
        print "<p>ERROR: Incorrect co-ordinate format.</p>"
        continue
    dec[i] = ddmm2deg(source[4:9])
    x, y = sky(RA[i], dec[i])
    if i >= delimIdx:
        #plt.plot(RA[i], dec[i], "mo")
        sky.plot(x, y, "mo")
    else:
        #plt.plot(RA[i], dec[i], "bo")
        sky.plot(x, y, "bo")

#plt.xlim(np.min(RA) - 1, np.max(RA) + 1)
#plt.ylim(np.min(dec) - 0.5, np.max(dec) + 0.5)

plt.show()

