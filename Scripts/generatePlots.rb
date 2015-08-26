#!/usr/local/bin/ruby

# generatePlots.rb
# Copies the previous night's (noon yesterday to noon today) data, removes bad
# lines, and generates plots.
#
# NOTE: To be run after 12:00 PM today.

# dry run flag
DryRun = false

# constants
NumComputeNodes = 4
ScriptsDir = "/home/artemis/Survey/Scripts"
PlotsDir = "/home/artemis/Survey/Plots"
LatestDataDir = "/home/artemis/Survey/Data/Latest"

# remove empty files from compute nodes
for i in 0...NumComputeNodes
  cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; find . -size 0 -exec rm -f {} \\;'"
  if DryRun
    print cmd, "\n"
  else
    %x[#{cmd} 2> /dev/null]
  end
  cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; find . -size 103c -exec rm -f {} \\;'"
  if DryRun
    print cmd, "\n"
  else
    %x[#{cmd} 2> /dev/null]
  end
end

# copy events files from the previous night's (noon yesterday to noon today)
# get yesterday string (ignore leap seconds)
yesterday = (Time.now - 86400).strftime("%Y%m%d")
# get today string
today = Time.now.strftime("%Y%m%d")

# copy files from all compute nodes
for i in 0...NumComputeNodes
  # copy last evening's data
  for j in 12..23
    cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; cp -af Beam?_dm_D#{yesterday}T%02d*.dat #{LatestDataDir}'" % j
    if DryRun
      print cmd, "\n"
    else
      %x[#{cmd} 2> /dev/null]
    end
  end
  # copy today morning's data
  for j in 0..13
    cmd = "ssh artemis@abc#{i} 'cd /data/Survey/abc#{i}/; cp -af Beam?_dm_D#{today}T%02d*.dat #{LatestDataDir}'" % j
    if DryRun
      print cmd, "\n"
    else
      %x[#{cmd} 2> /dev/null]
    end
  end
end

# remove bad lines
cmd = "ls *dat | xargs -n 1 #{ScriptsDir}/removeBadLines.rb"
if DryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end

# generate plots
cmd = "#{ScriptsDir}/plotFRB.py -lon 0 -f '*.dat'"
if DryRun
  print cmd, "\n"
else
  %x[#{cmd} > #{PlotsDir}/#{today}.log 2>&1]
end
cmd = "mv #{LatestDataDir}/*png #{PlotsDir}"
if DryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end
cmd = "rm -f #{LatestDataDir}/*dat"
if DryRun
  print cmd, "\n"
else
  %x[#{cmd} 2> /dev/null]
end

