#!/usr/bin/python
import os,fnmatch
import sys
import numpy as np
import ephem
import argparse
import matplotlib
import matplotlib.dates as md
import time
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.cm as cmx
import pylab
import string
import Image
from pytz import timezone
from datetime import datetime, tzinfo
from datetime import timedelta
__author__ = 'ak77'

parser = argparse.ArgumentParser(description='Plotter for ALFABURST output')
parser.add_argument('-lon','--longitude', help='Telescope longitude for LST calculation',required=True)
parser.add_argument('-f','--filename',help='Input filename', required=True)
args = parser.parse_args()

files = [item for item in os.listdir('.') if fnmatch.fnmatch(item, args.filename)]
filesorted=sorted(files) 
print filesorted
lon = float(args.longitude)

plt.close('all')
fig = plt.figure(figsize=(16.5,9)) 
ax = plt.axes([0.075, 0.10, 0.75, 0.85])
#fig, ax = plt.subplots(num=1, figsize=(30,12), facecolor='w', edgecolor='k')
cm = plt.get_cmap('jet')
font = {'family' : 'normal',
        'weight' : 'bold',
        'size'   : 18}

matplotlib.rc('font', **font)
filenumber = len(files)
index = 0
empties = 0
for f in filesorted:
    plotlabel = f[0:5]
    print plotlabel
    try:
        dataraw = np.genfromtxt(f, comments='#', delimiter=',')
    except IOError:
        dataraw = np.array([]) # Or np.empty or np.zeros...
    if dataraw.size == 0:
        print 'Empty file'
        empties += 1
        continue
    if dataraw.shape == (4,):
        # only one line in file
        dataraw = np.reshape(dataraw, (1,4))
    sortindex = np.lexsort((dataraw[:,3],dataraw[:,2],dataraw[:,1],dataraw[:,0]))

    data = dataraw[sortindex]
    datacopy = dataraw[sortindex]
# Add data to arrays after checking they are unique
    
    dataidx = 1
    for idx in range(1,data.shape[0]):
#        print idx
#        print 'added ', idx, np.around(datacopy[idx,0],6), np.around(datacopy[idx,1],0)
#        print 'added ', idx, np.around(datacopy[idx-1,0],6), np.around(datacopy[idx-1,1],0)
        if np.around(datacopy[idx,0],6) != np.around(datacopy[idx-1,0],6) \
                or np.around(datacopy[idx,1],0) != np.around(datacopy[idx-1,1],0):
            data[dataidx,:] = datacopy[idx,:]
            dataidx += 1
#            print 'BINGO'
#    dataidx -= 1
    print 'Found ',dataidx, ' unique entries out of ', data.shape[0] 
    mjd = data[:dataidx,0]
    dm = data[:dataidx,1]
    snr = np.array(10.0 * (data[:dataidx,2] - 2 * index))
    binnumber = np.array(data[:dataidx,3])


    dates = np.array(mjd - 15019.5)
    myObserver = ephem.Observer()
    #myObserver.lon = '0'
    # Arecibo longitude
    myObserver.lon = '-66:45.185'
#myObserver.lon = lon * 180.0 / 3.1415
    print myObserver.lon
#myObserver.lat = '51.145'
    listofdates = []
    listoflst = []
    hourmin = 0
    myObserver.date = (dates[0])
    date1 = datetime.date(ephem.localtime(myObserver.date))
    time1 = datetime.time(ephem.localtime(myObserver.date))
    print date1
    thislst = str(myObserver.sidereal_time())
    lstdt = datetime.strptime(thislst,'%H:%M:%S.%f')
    lsttime = lstdt.time()
    hour1 = lsttime.hour
# if the first event happens when LST < 12 and LT > 12
# already define this as the next sidereal day
    if (hour1 < 12 and time1.hour > 12):
        date1 = date1 + timedelta(days=1)
    for i in range (dates.size):
        myObserver.date = (dates[i])
        #print myObserver.date
        listofdates.append(ephem.localtime(myObserver.date))
        datadate = datetime.date(ephem.localtime(myObserver.date))
        thislst = str(myObserver.sidereal_time())
        # make sure the hour is not 24, but 0
        hour = thislst[:string.find(thislst, ":")]
        if 24 == int(hour):
            thislst = "00" + thislst[string.find(thislst, ":"):]
        lstdt = datetime.strptime(thislst,'%H:%M:%S.%f')
        lsttime = lstdt.time()
#        print 'Testing -----------------'
#        print lstdt
        if (lsttime.hour < hour1):
            date1 = date1 + timedelta(days=1)
            print lsttime.hour, hour1
            print 'forced date change'
            print listofdates[i-1]
            print listofdates[i]
            print 'LST time to be added'
            print datetime.combine(thedate,lsttime)
        thedate = date1
        listoflst.append(datetime.combine(thedate,lsttime))
        hour1 = lsttime.hour
#        print 'LST time added'
#        print datetime.combine(thedate,lsttime)
    print '------'
#mdates = md.date2num(listofdates)
    mdates = md.date2num(listoflst)
#    dm = dm - 0.5 + index / 20.
#    plt.scatter(mdates, dm, c = cm(index*255/8 + np.log2(binnumber)), s = snr, label = plotlabel, lw = 0)
    plt.scatter(mdates, dm, c = cm(index*255/8), s = snr, label = plotlabel, lw = 0)
    plt.plot_date(mdates, dm, c = cm(index*255/8))
    print 'Date range and lst range'
    print listofdates[-1], listofdates[0]
    print listoflst[-1], listoflst[0]
    del data, datacopy, dataraw, dates, mdates, listofdates, listoflst, snr
    print 'Next...'
    index += 1
if (empties == filenumber):
    print 'No data... exiting.'
    sys.exit()
datename=f[9:25]
print datename
handles,labels = ax.get_legend_handles_labels()
#ax.legend(handles, labels, loc='upper right')
lgd = ax.legend(handles, labels, loc='upper center', bbox_to_anchor=(1.125,0.85))
ax.grid()
plt.xlabel('LST time')
plt.ylabel('DM pc/cm^3')
#lims = plt.xlim()
## plt.xlim([lims[0]-0.01, lims[1]+0.01])

## Ensure the x window is always 2 days - it is unlikely to be more
#if (np.ceil(lims[1]) - np.floor(lims[0]) == 1):
#    plt.xlim([np.floor(lims[0])-0.01, np.ceil(lims[1])+1.01])
#else:
#    plt.xlim([np.floor(lims[0])-0.01, np.ceil(lims[1])+0.01])
    
lims = plt.ylim()
#plt.ylim([-9, lims[1]])
plt.ylim([-10, 2570])
# rotate and align the tick labels so they look better
fig.autofmt_xdate()
            
# use a more precise date string for the x axis locations in the toolbar
ax.fmt_xdata = md.DateFormatter('%Y/%m/%d %H:%M:%S.%f')
plt.title(date1)

im = Image.open('/home/artemis/Survey/Images/Artemis.png')
height = im.size[1]
width = im.size[0]

# We need a float array between 0-1, rather than
# a uint8 array between 0-255
im = np.array(im).astype(np.float) / 255

# With newer (1.0) versions of matplotlib, you can 
# use the "zorder" kwarg to make the image overlay
# the plot, rather than hide behind it... (e.g. zorder=10)
fig.figimage(im, fig.bbox.xmax + width / 5 , fig.bbox.ymax + height/2 - 20)
#plt.show()
#print listofdates
outputfile = 'AllBeams_' + datename + '.png'
plt.savefig(outputfile)
pylab.draw()
