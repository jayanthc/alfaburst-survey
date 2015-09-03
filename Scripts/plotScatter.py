#!/usr/bin/python

# plotScatter.py
# Makes a plot of data from input event files. It is expected that all beams
# from one observing session is given as input.

import sys
import getopt
import numpy as np
import ephem
import matplotlib as mp
import Image

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
    print "    -r  --dont-remove-rfi                ",                        \
          "Do not remove RFI"
    print "    -l  --no-logo                        ",                        \
          "Do not use logo"
    print "    -s  --plot-to-screen                 ",                        \
          "Plot to screen"
    print "                                         ",                        \
          "(default is to file)"
    return


# default values
DontRemoveRFI = False           # dont-remove-rfi flag
NoLogo = False                  # no-logo flag
PlotToScreen = False            # plot-to-screen flag
DMMin = 0.0                     # cm^-3 pc
DMMax = 2560.0                  # cm^-3 pc
DMBinWidth = 6.0                # cm^-3 pc
TimeBinWidth = 16.0             # seconds
SecondsPerDay = 86400.0         # seconds

# get the command line arguments
ProgName = sys.argv[0]
OptsShort = "hrls"
OptsLong = ["help", "dont-remove-rfi", "no-logo", "plot-to-screen"]

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
    elif o in ("-r", "--dont-remove-rfi"):
        DontRemoveRFI = True
        optind = optind + 1
    elif o in ("-l", "--no-logo"):
        NoLogo = True
        optind = optind + 1
    elif o in ("-s", "--plot-to-screen"):
        PlotToScreen = True
        optind = optind + 1
    else:
        PrintUsage(ProgName)
        sys.exit(1)

# get number of files
numFiles = len(sys.argv) - optind

if not PlotToScreen:
    mp.use("Agg")
# pyplot should be imported after backend selection
import matplotlib.pyplot as plt

# loop through input files and find the minimum and maximum MJD
minMJD = 100000.0
maxMJD = 0.0
files = sys.argv[optind:]
for f in files:
    print "Preprocessing %s..." % f
    # read the file; data is [MJD, DM, S/N, smoothing width]; ndmin=2 ensures
    # that files with a single event are handled properly
    data = np.loadtxt(f, dtype=float, delimiter=",", comments="#", ndmin=2)
    # get time range
    minMJD = np.fmin(np.min(data[:,0]), minMJD)
    maxMJD = np.fmax(np.max(data[:,0]), maxMJD)

# calculate number of time bins
numTimeBins = int(np.ceil((maxMJD - minMJD) * SecondsPerDay / TimeBinWidth))
# calculate number of DM bins
numDMBins = int(np.ceil((DMMax - DMMin) / DMBinWidth))

# set up a large figure (16 inches x 9 inches)
fig = plt.figure(figsize=(16.0, 9.0))
# set the axes: Left, bottom, width, height
plt.axes([0.075, 0.10, 0.75, 0.825])

cmap = plt.get_cmap("jet")

# loop through input files and generate 2D histograms
numBeams = 7
beamScale = 3
plotLabels = []
histSum = np.zeros((numDMBins, numTimeBins))
i = 0
for f in files:
    print "Processing %s..." % f
    beamID = int(f[4])
    # read the file; data is [MJD, DM, S/N, smoothing width]; ndmin=2 ensures
    # that files with a single event are handled properly
    data = np.loadtxt(f, dtype=float, delimiter=",", comments="#", ndmin=2)
    # 2D-bin the axis ranges
    hist, ybe, xbe = np.histogram2d(data[:,1], data[:,0],                     \
                                    bins=(numDMBins,numTimeBins),             \
                                    range=((DMMin,DMMax),(minMJD,maxMJD)),    \
                                    weights=data[:,2], normed=True)
    if not DontRemoveRFI:
        # remove RFI; if >= 70% of DM bins in a time bin contains events, set
        # all those to 0
        for j in range(numTimeBins):
            if len(np.where(hist[:,j] > 0)[0]) >= int(numDMBins * 0.70):
                hist[:,j] = 0
    # extract x, y of non-zero elements
    events = np.where(hist > 0)
    dm = events[0]
    lst = events[1]
    # no need to make a plot if there are no events left
    if 0 == len(dm):
        continue
    # shift the values up and scale them appropriately for better plotting
    size = 2 * (hist[hist > 0] + 10 + (beamScale * numBeams)                  \
                - (beamScale * beamID))
    col = cmap(beamID * 255 / numBeams)
    plotLabels.append(r"${\rm Beam~%d}$" % beamID)
    plt.scatter(lst, dm, s=size, c=col, label=plotLabels[i])
    histSum += hist
    i += 1

# the data is full of RFI
if 0 == i:
    print "Data is full of RFI. No plots will be generated."
    sys.exit()

# initialize TeX stuff
fontSize = 16
texInit(fontSize)

# calculate aspect ratio based on the number of bins used
aspect = float(numTimeBins) / (2 * numDMBins)

# get date
date = files[0][10:18]
# get time
time = files[0][19:25]

ticks, labels = plt.xticks()
plt.xticks(ticks,                                                             \
           map(mjd2lst,                                                       \
               minMJD + (ticks * ((maxMJD - minMJD) / numTimeBins))))
plt.xlim(0, numTimeBins)

# use these ticks instead of the default ones
yVals = np.array([0.0, 500.0, 1000.0, 1500.0, 2000.0, 2500.0])
ticks = numDMBins * yVals / (DMMax - DMMin)
plt.yticks(ticks,                                                             \
           map(lambda val: r"$%4.0f$" % val,                                  \
               ticks * ((DMMax - DMMin) / numDMBins)))
plt.ylim(0, numDMBins)

legend = plt.legend(plotLabels, loc="upper left", fontsize=fontSize,          \
                    bbox_to_anchor=(1.0, 0.8), scatterpoints=1, frameon=False)
# set the legend key size manually to make them equal for all beams
for j in range(i):
    legend.legendHandles[j]._sizes = [40]

plt.title(r"${\rm %s:%s}$" % (date, time))
plt.xlabel(r"${\rm LST}$")
plt.ylabel(r"${\rm DM~(cm}^{-3}{\rm~pc)}$")

if not NoLogo:
    # import ALFABURST logo
    logo = Image.open("/home/artemis/Survey/Images/alfaburst_logowithtext.png")
    width = logo.size[0]
    height = logo.size[1]

    # convert to float values between 0 and 1
    logo = np.array(logo).astype(np.float) / 255

    fig.figimage(logo, 2 * fig.bbox.xmax - 10, 2 * fig.bbox.ymax - 150,       \
                 zorder=1)

if PlotToScreen:
    plt.show()
else:
    # build filename
    fileImg = "AllBeams_D" + date + "T" + time + ".png"
    # use a high DPI for high resolution
    plt.savefig(fileImg, dpi=192, bbox_inches="tight")

