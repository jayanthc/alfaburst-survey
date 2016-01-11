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
    -p  --png                            Generate PNG images
                                         (default is GIF)
    -d  --date <date>                    Start at this date instead of today
                                         (in the form YYYYMMDD)
    -v  --verbose                        Verbose mode
  EOF
end


opts = GetoptLong.new(
  [ "--help",       "-h", GetoptLong::NO_ARGUMENT ],
  [ "--nodryrun",   "-n", GetoptLong::NO_ARGUMENT ],
  [ "--png",        "-p", GetoptLong::NO_ARGUMENT ],
  [ "--date",       "-d", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--verbose",    "-v", GetoptLong::NO_ARGUMENT ]
)

# dry run flag
dryRun = true
# PNG flag
makePNG = false
# verbose flag
verbose = false
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
    when "--png"
      # set the PNG flag to true
      makePNG = true
    when "--date"
      today = arg
      # NOTE: the date is assumed to be of the form YYYYMMDD, without any
      # validation
      # set timeNow to be mid-day on the given day
      timeNow = Time.new(today[0..3].to_i, today[4..5].to_i, today[6..7].to_i, 12, 0, 0)
    when "--verbose"
      # set the verbose flag to true
      verbose = true
  end
end

# constants
NumComputeNodes = 4
ScriptsDir = "/home/artemis/Survey/Scripts"
JSDir = "/home/artemis/Survey/www/js"
PlotsDir = "/home/artemis/Survey/Plots"
LatestDataDir = "/home/artemis/Survey/Data/Latest"
ComputeNodeDataDir = "/data/Survey/Data"

# remove any pre-existing data files from the latest data directory
cmd = "rm -f #{LatestDataDir}/*dat"
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  %x[#{cmd} > /dev/null 2>&1]
end

# remove empty files from compute nodes
for i in 0...NumComputeNodes
  cmd = "ssh artemis@abc#{i} 'cd #{ComputeNodeDataDir}; find . -size 0 -exec rm -f {} \\;'"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end
  cmd = "ssh artemis@abc#{i} 'cd #{ComputeNodeDataDir}; find . -size 103c -exec rm -f {} \\;'"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
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
if dryRun or verbose
    print "Today is #{today}. Yesterday was #{yesterday}.\n"
end

# copy files from all compute nodes
for i in 0...NumComputeNodes
  # copy last evening's data
  for j in 12..23
    cmd = "ssh artemis@abc#{i} 'cd #{ComputeNodeDataDir}; cp -af Beam?_dm_D#{yesterday}T%02d*.dat #{LatestDataDir}'" % j
    if dryRun or verbose
      print cmd, "\n"
    end
    if not dryRun
      %x[#{cmd} > /dev/null 2>&1]
    end
  end
  # copy today morning's data
  for j in 0..13
    cmd = "ssh artemis@abc#{i} 'cd #{ComputeNodeDataDir}; cp -af Beam?_dm_D#{today}T%02d*.dat #{LatestDataDir}'" % j
    if dryRun or verbose
      print cmd, "\n"
    end
    if not dryRun
      %x[#{cmd} > /dev/null 2>&1]
    end
  end
end

# check if there are files to process, if not exit
cmd = "ls #{LatestDataDir}/*.dat | wc -l"
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  numFiles = (%x[#{cmd}]).to_i
  if 0 == numFiles
    %x[echo "No files." >> #{PlotsDir}/#{today}.log]

    # clean up
    cmd = "rm -f #{LatestDataDir}/*dat"
    if dryRun or verbose
      print cmd, "\n"
    end
    if not dryRun
      %x[#{cmd} > /dev/null 2>&1]
    end

    exit
  end
end

# remove bad lines
cmd = "ls #{LatestDataDir}/*.dat | xargs -n 1 #{ScriptsDir}/removeBadLines.rb"
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  %x[#{cmd} > /dev/null 2>&1]
end

# find unique epochs by extracting the hour and minute, and create globs
# NOTE: this is not a perfect glob, but it will work because we restrict
# ourselves to a 24-hour window
cmd = "ls #{LatestDataDir}/*.dat | cut -b 53,54,55,56 | sort -n | uniq | sed 's/^/Beam?_dm_D*T/' | sed 's/$/*.dat/'"
if dryRun or verbose
  print cmd, "\n"
end
# this needs to be done for the loop below
epochGlobs = %x[#{cmd}]

# generate a plot per epoch
epochGlobs.each_line do |epochGlob|
  if makePNG
    cmd = "cd #{LatestDataDir}; #{ScriptsDir}/plotScatter.py #{LatestDataDir}/#{epochGlob.strip()}"
  else
    cmd = "cd #{LatestDataDir}; #{ScriptsDir}/plotScatterGIF.py #{LatestDataDir}/#{epochGlob.strip()}"
  end
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} >> #{PlotsDir}/#{today}.log 2>&1]
  end
end

# check if there are files to process, if not exit
if makePNG
  cmd = "ls #{LatestDataDir}/*.png | wc -l"
else
  cmd = "ls #{LatestDataDir}/*.gif | wc -l"
end
if dryRun or verbose
  print cmd, "\n"
end
numPlots = (%x[#{cmd}]).to_i
if dryRun or verbose
  print "Number of plots = #{numPlots}\n"
end
if 0 == numPlots
    %x[echo "No plots." >> #{PlotsDir}/#{today}.log]

    # remove data files from the latest data directory
    cmd = "rm -f #{LatestDataDir}/*dat"
    if dryRun or verbose
      print cmd, "\n"
    end
    if not dryRun
      %x[#{cmd} > /dev/null 2>&1]
    end

    exit
end

if makePNG
  # scp JS files to the web server
  cmd = "scp #{LatestDataDir}/*js alfafrb@maunabo:public_html/js/"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end

  # generate web pages
  cmd = "#{ScriptsDir}/generatePages.rb"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end

  # scp web pages to the web server
  cmd = "scp #{LatestDataDir}/*htm alfafrb@maunabo:public_html/"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end

  # remove web pages
  cmd = "rm -f #{LatestDataDir}/*htm"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end

  # scp images to the web server
  cmd = "scp #{LatestDataDir}/*png alfafrb@maunabo:public_html/images/"
  if dryRun or verbose
    print cmd, "\n"
  end
  if not dryRun
    %x[#{cmd} > /dev/null 2>&1]
  end
end

# move plots to plots directory
if makePNG
  cmd = "mv #{LatestDataDir}/*png #{PlotsDir}"
else
  cmd = "mv #{LatestDataDir}/*gif #{PlotsDir}"
end
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  %x[#{cmd} > /dev/null 2>&1]
end

# clean up
# remove JS files
cmd = "rm -f #{LatestDataDir}/*js"
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  %x[#{cmd} > /dev/null 2>&1]
end

# remove data files from the latest data directory
cmd = "rm -f #{LatestDataDir}/*dat"
if dryRun or verbose
  print cmd, "\n"
end
if not dryRun
  %x[#{cmd} > /dev/null 2>&1]
end

