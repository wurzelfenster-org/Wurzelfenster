#!/usr/bin/env python

import sane
from PIL import Image
import argparse
import os
import datetime
from functools import wraps
from time import time

def timed(f):
  @wraps(f)
  def wrapper(*args, **kwds):
    start = time()
    result = f(*args, **kwds)
    elapsed = time() - start
    print("%s took %d time to finish" % (f.__name__, elapsed))
    return result
  return wrapper

parser = argparse.ArgumentParser()
parser.add_argument('--resolution',type=int, help = 'scan resolution in dpi, dependend on scanner hardware')

args = parser.parse_args()

depth = 8
mode = 'color'
resolution = args.resolution

home = os.path.expanduser('~')
cwd = home + '/TimelapseScanner/'
scanCountFile = cwd + "scanCount.txt"

# create cwd if it does not exist
if not os.path.exists(cwd):
    try:
        os.mkdir(cwd)
    except:
        print(f'Can not create directory {cwd}')

# create counter file on first excecution
if not os.path.isfile(scanCountFile):
    try:
        f = open(scanCountFile, "w")
        f.write("0")
        f.close()
    except:
        print("Can not write file 'scanCount.txt'")

# read counter
try:
    f = open(scanCountFile, "r")
    line = f.readline()
    f.close()
    if len(line)!=0:
        scanCount = line
    else:
        scanCount = 0
except:
    print('Could not read counter')


print(f'Scanning image number:{scanCount}')

#
# Initialize sane
#
ver = sane.init()
print('SANE version:', ver)

#
# Get devices
#
devices = sane.get_devices(localOnly=True)
print('Available devices:', devices)

#
# Open first device
#
dev = sane.open(devices[0][0])

#
# Set some options
#
params = dev.get_parameters()
try:
    dev.depth = depth
except:
    print('Cannot set depth, defaulting to %d' % params[3])

try:
    dev.mode = mode
except:
    print('Cannot set mode, defaulting to %s' % params[0])

try:
    dev.resolution = resolution
except:
    print('Cannot set mode, defaulting to %s' % params[0])

#try:
#    dev.br_x = 320.
#    dev.br_y = 240.
#except:
#    print('Cannot set scan area, using default')

params = dev.get_parameters()
print('Device parameters:', params)

#
# Start a scan and get and PIL.Image object
#

@timed
def scan_image():
    dev.start()
    im = dev.snap()

# save image
@timed
def save_image():
    # save image in original resolution
    #im.save(f'{cwd}scan_{scanCount}.png')
    im.save(f'{cwd}scan_{scanCount}.webp',"WEBP")

scan_image()
save_image()

# update counter
try: 
    f = open(scanCountFile, "w")
    f.write(f'{int(scanCount)+1}')
    f.close()
except:
    print(f"Could not update counter in file: '{scanCountFile}'")

dev.close()
