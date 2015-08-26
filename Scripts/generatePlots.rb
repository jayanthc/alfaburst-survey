#!/usr/local/bin/ruby

# generatePlots.rb
# Copies the previous night's (noon yesterday to noon today) data, removes bad
# lines, and generates plots.
#
# Usage: generatePlots.rb [options]
#     -h  --help                           Display this usage information
#     -n  --nodryrun                       Do a non-dry-run
#                                          (default is dry run)
#     -d  --date <date>                    Start at this date instead of today
#                                          (in the form YYYYMMDD)
# NOTE: To be run after 12:00 PM today.

require "getoptlong"

def printUsage(progName)
  puts <<-EOF
Usage: #{progName} [options]
    -h  --help                           Display this usage information
    -n  --nodryrun                       Do a non-dry-run
                                         (default is dry run)
    -d  --date <date>                    Start at this date instead of today
                                         (in the form YYYYMMDD)
  EOF
end


opts = GetoptLong.new(
  [ "--help",       "-h", GetoptLong::NO_ARGUMENT ],
  [ "--nodryrun",   "-n", GetoptLong::NO_ARGUMENT ],
  [ "--date",       "-d", GetoptLong::REQUIRED_ARGUMENT ]
)

# dry run flag
dryRun = true
# today's date and time
today = nil
timeNow = nil

opts.each do |opt, arg|
  case opt
    when "--help"
      printUsage($PROGRAM_NAME)
      exit
    when "--nodryrun"
      # set the dry run flag to false
      dryRun = false
    when "--date"
      today = arg
      # NOTE: the date is assumed to be of the form YYYYMMDD, without any
      # validation
      # set timeNow to be mid-day on the given day
      timeNow = Time.new(today[0..3].to_i, today[4..5].to_i, today[6..7].to_i, 12, 0, 0)
  end
end

# constants
NumComputeNodes = 4
ScriptsDir = "/home/artemis/Survey/Scripts"
PlotsDir = "/home/artemis/Survey/Plots"
LatestDataDir = "/home/artemis/Survey/Data/Latest"

# remove empty files from compute nodes
for i in 0...NumComputeNodes
  cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; find . -size 0 -exec rm -f {} \\;'"
  if dryRun
    print cmd, "\n"
  else
    %x[#{cmd} 2> /dev/null]
  end
  cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; find . -size 103c -exec rm -f {} \\;'"
  if dryRun
    print cmd, "\n"
  else
    %x[#{cmd} 2> /dev/null]
  end
end

# copy events files from the previous night's (noon yesterday to noon today)
if nil == today
    timeNow = Time.now
    # get today string
    today = timeNow.strftime("%Y%m%d")
end
# get yesterday string (ignore leap seconds)
yesterday = (timeNow - 86400).strftime("%Y%m%d")
if dryRun
    print "Today is #{today}. Yesterday was #{yesterday}.\n"
end

# copy files from all compute nodes
for i in 0...NumComputeNodes
  # copy last evening's data
  for j in 12..23
    cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; cp -af Beam?_dm_D#{yesterday}T%02d*.dat #{LatestDataDir}'" % j
    if dryRun
      print cmd, "\n"
    else
      %x[#{cmd} 2> /dev/null]
    end
  end
  # copy today morning's data
  for j in 0..13
    cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; cp -af Beam?_dm_D#{today}T%02d*.dat #{LatestDataDir}'" % j
    if dryRun
      print cmd, "\n"
    else
      %x[#{cmd} 2> /dev/null]
    end
  end
end

# remove bad lines
cmd = "ls *.dat | xargs -n 1 #{ScriptsDir}/removeBadLines.rb"
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end

# find unique epochs by extracting the hour and minute, and create globs
# NOTE: this is not a perfect glob, but it will work because we restrict
# ourselves to a 24-hour window
cmd = "ls *.dat | cut -b 20,21,22,23 | sort -n | uniq | sed 's/^/Beam?_dm_D*T/' | sed 's/$/*.dat/'"
if dryRun
  print cmd, "\n"
end
# this needs to be done for the loop below
epochGlobs = %x[#{cmd}]

# generate a plot per epoch
epochGlobs.each_line do |epochGlob|
  cmd = "#{ScriptsDir}/plotGIF.py #{epochGlob.strip()}"
  if dryRun
    print cmd, "\n"
  else
    %x[#{cmd} >> #{PlotsDir}/#{today}.log 2>&1]
  end
end

# move plots to plots directory
cmd = "mv #{LatestDataDir}/*gif #{PlotsDir}"
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end

# remove data files from the latest data directory
cmd = "rm -f #{LatestDataDir}/*dat"
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end

