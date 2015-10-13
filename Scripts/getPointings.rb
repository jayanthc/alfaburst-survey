#!/usr/local/bin/ruby

# getPointings.rb
# Get all ALFA beam pointings from the SERENDIP VI SCRAM dump, given an MJD.
#
# Usage: getPointings.rb [options]
#     -h  --help                           Display this usage information
#     -m  --mjd <mjd>                      MJD of the pointings

require "getoptlong"

def printUsage(progName)
  puts <<-EOF
Usage: #{progName} [options]
    -h  --help                           Display this usage information
    -m  --mjd <mjd>                      MJD of the pointings
  EOF
end


opts = GetoptLong.new(
  [ "--help",       "-h", GetoptLong::NO_ARGUMENT ],
  [ "--mjd",        "-m", GetoptLong::REQUIRED_ARGUMENT ]
)

# MJD of the pointings
mjd = 0.0

# constants
SCRAMDumpDir = "/data/serendip6"
TempDir = "/home/jayanth"

opts.each do |opt, arg|
  case opt
    when "--help"
      printUsage($PROGRAM_NAME)
      exit
    when "--mjd"
      # set the MJD
      mjd = arg.to_f
  end
end

# convert MJD to unix time
jd = mjd + 2400000.5
unixTime = ((jd - 2440587.5) * 86400).round
puts unixTime

# figure out which SCRAM dump file to process
cmd = "ls #{SCRAMDumpDir}/scramdump.*.gz* | cut -d '.' -f 2"
puts cmd
timestampStrings = %x[#{cmd}]
timestamps = timestampStrings.split("\n").map { |x| x.to_i}

timestamp = 0
timestamps.each { |t|
  if t > unixTime
    timestamp = t
    break
  end
}

scramDumpGZ = Dir.glob("#{SCRAMDumpDir}/scramdump.#{timestamp}.gz*")[0]
puts scramDumpGZ

# copy file to temp directory
cmd = "cp -a #{scramDumpGZ} #{TempDir}/"
puts cmd
%x[#{cmd}]
# build path to file in temp directory
scramDumpGZ = TempDir + "/" + File.basename(scramDumpGZ)
# gunzip with any suffix, preserving the name, forcing
cmd = "gunzip --force --name --suffix '' #{scramDumpGZ}"
puts cmd
%x[#{cmd}]
scramDump = TempDir + "/scramdump.#{timestamp}"

# get (only the latest) pointings at the given Unix time from the SCRAM dump
cmd = "s6_observatory -nodb -stdout -infile #{scramDump} 2>&1 > /dev/null | grep #{unixTime} | sort | uniq | grep RA0 | tail -1"
puts cmd
pointings = %x[#{cmd}]
puts pointings

# remove the copied scram dump
cmd = "rm -f #{scramDump}"
puts cmd
%x[#{cmd}]

