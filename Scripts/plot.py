#!/usr/bin/python

# plot.py
# Makes a GIF animation of data from input event files. It is expected that all
# beams from one observing session is given as input.

import sys
import getopt
import numpy as np
import ephem
import matplotlib as mp
mp.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.animation as ma
import matplotlib.dates as md
import datetime as dt

def texInit(fontsize):
    # set plotting font properties
    font = {"family" : "serif",
            "weight" : "regular",
            "size"   : fontsize}
    plt.rc("font", **font)
    # force matplotlib to use Type 1 fonts instead of Type 3
    mp.rcParams["ps.useafm"] = True
    mp.rcParams["pdf.use14corefonts"] = True
    mp.rcParams["text.usetex"] = True


def animate(frame):
    plt.imshow(hist[frame], origin="lower", interpolation="nearest",          \
               cmap="Blues", aspect=aspect, vmax=vmax)

    ticks, labels = plt.xticks()
    plt.xticks(ticks,                                                         \
               map(mjd2lst,                                                   \
                   minMJD + (ticks * ((maxMJD - minMJD) / numTimeBins))))
    plt.xlim(0, numTimeBins)

    ticks, labels = plt.yticks()
    plt.yticks(ticks,                                                         \
               map(lambda val: r"$%g$" % val,                                 \
                   ticks * ((DMMax - DMMin) / numDMBins)))
    plt.ylim(0, numDMBins)

    plt.title(r"${\rm %s:%s~Beam~%s}$" % (date, time, beams[frame]))
    plt.xlabel(r"${\rm LST}$")
    plt.ylabel(r"${\rm DM~(cm}^{-3}{\rm~pc)}$")


def mjd2lst(mjd):
    arecibo = ephem.Observer()
    arecibo.lon = "-66:45.185"
    arecibo.date = mjd - 15019.5
    # convert MJD to LST and extract %H:%M:%S (no trailing decimals)
    LST = str(arecibo.sidereal_time())[:-3]
    return r"${\rm %s}$" % LST


# function definitions
def PrintUsage(ProgName):
    "Prints usage information."
    print "Usage: " + ProgName + " [options] <input-files>"
    print "    -h  --help                           ",                        \
          "Display this usage information"
    print "    -s  --plot-to-screen                 ",                        \
          "Plot to screen"
    print "                                         ",                        \
          "(default is to file)"
    return


# default values
PlotToScreen = False            # plot-to-screen flag
DMMin = 0.0                     # cm^-3 pc
DMMax = 2560.0                  # cm^-3 pc
DMBinWidth = 4.0                # cm^-3 pc
TimeBinWidth = 16.0             # seconds
SecondsPerDay = 86400.0         # seconds

# get the command line arguments
ProgName = sys.argv[0]
OptsShort = "hs"
OptsLong = ["help", "plot-to-screen"]

# get the arguments using the getopt module
try:
    (Opts, Args) = getopt.getopt(sys.argv[1:], OptsShort, OptsLong)
except getopt.GetoptError, ErrMsg:
    # print usage information and exit
    sys.stderr.write("ERROR: " + str(ErrMsg) + "!\n")
    PrintUsage(ProgName)
    sys.exit(1)

optind = 1
# parse the arguments
for o, a in Opts:
    if o in ("-h", "--help"):
        PrintUsage(ProgName)
        sys.exit()
    elif o in ("-s", "--plot-to-screen"):
        PlotToScreen = True
        optind = optind + 1
    else:
        PrintUsage(ProgName)
        sys.exit(1)

# get number of files
numFiles = len(sys.argv) - optind

# loop through input files and find the minimum and maximum MJD
minMJD = 100000.0
maxMJD = 0.0
files = sys.argv[optind:]
for f in files:
    print "Loading %s..." % f
    # read the file; data is [MJD, DM, S/N, smoothing width]
    data = np.loadtxt(f, dtype=float, delimiter=",", comments="#")
    # get time range
    minMJD = np.fmin(np.min(data[:,0]), minMJD)
    maxMJD = np.fmax(np.max(data[:,0]), maxMJD)

# calculate number of time bins
numTimeBins = (maxMJD - minMJD) * SecondsPerDay / TimeBinWidth
# calculate number of DM bins
numDMBins = (DMMax - DMMin) / DMBinWidth

# loop through input files and generate 2D histograms
hist = np.zeros((numFiles, numDMBins, numTimeBins))
i = 0
beams = []
for f in files:
    # read the file; data is [MJD, DM, S/N, smoothing width]
    data = np.loadtxt(f, dtype=float, delimiter=",", comments="#")
    # generate beam ID array to be used for plot title
    beams.append(f[4])
    # 2D-bin the axis ranges
    hist[i], xbe, ybe = np.histogram2d(data[:,1], data[:,0],                  \
                                       bins=(numDMBins,numTimeBins),          \
                                       range=((DMMin,DMMax),(minMJD,maxMJD)), \
                                       weights=data[:,2])
    i += 1

# initialize TeX stuff
texInit(16)

# calculate aspect ratio based on the number of bins used
aspect = float(numTimeBins) / (2 * numDMBins)
# use the S/N threshold of the survey
vmax = 10

# get date
date = files[0][10:18]
# get time
time = files[0][19:25]

# set up a large figure (16 inches x 9 inches)
fig = plt.figure(figsize=(16.0, 9.0))
anim = ma.FuncAnimation(fig, animate, frames=numFiles)
# build filename
fileImg = "AllBeams_D" + date + "T" + time + ".gif"
# use a high DPI for high resolution
anim.save(fileImg, dpi=192, writer="imagemagick", fps=1)

