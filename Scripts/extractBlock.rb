#!/usr/local/bin/ruby

# extractBlock.rb
# Extracts a given buffer from an ALFABURST filterbank dump and saves it as a
# separate filterbank file.
#
# Usage: extractBlock.rb [options] <filterbank-file>
#     -h  --help                           Display this usage information
#     -b  --buffer                         Buffer number
#     -m  --mjd                            Starting MJD of the extracted block

require "getoptlong"

def printUsage(progName)
  puts <<-EOF
Usage: #{progName} [options] <filterbank-file>
    -h  --help                           Display this usage information
    -b  --buffer                         Buffer number
    -m  --mjd                            Starting MJD of the extracted block
  EOF
end


opts = GetoptLong.new(
  [ "--help",       "-h", GetoptLong::NO_ARGUMENT ],
  [ "--buffer",     "-b", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--mjd",        "-m", GetoptLong::REQUIRED_ARGUMENT ]
)

# buffer number
buffer = 0
# starting MJD
mjd = 0.0

# constants
ComputeNodeDataDir = "/data/Survey/Data"

opts.each do |opt, arg|
  case opt
    when "--help"
      printUsage($PROGRAM_NAME)
      exit
    when "--buffer"
      # set the buffer number
      buffer = arg.to_i
    when "--mjd"
      # set the starting MJD
      mjd = arg.to_f
  end
end

fileData = ARGV[0]
# user input validation
if nil == fileData
    STDERR.puts "ERROR: Data file not given!"
    printUsage($PROGRAM_NAME)
    exit
end
# check if the file exists, if not exit
%x[ls #{fileData} > /dev/null 2>&1]
if $?.exitstatus != 0
    STDERR.puts "ERROR: Data file not found!"
    printUsage($PROGRAM_NAME)
    exit
end

# run dd to copy the data to a temp file
%x[dd if=#{fileData} of=#{tempData} bs=1 count=#{dataBytes} skip=#{headerBytes}]

__END__
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
  if makePNG
    cmd = "#{ScriptsDir}/plotScatter.py #{epochGlob.strip()}"
  else
    cmd = "#{ScriptsDir}/plotScatterGIF.py #{epochGlob.strip()}"
  end
  if dryRun
    print cmd, "\n"
  else
    %x[#{cmd} >> #{PlotsDir}/#{today}.log 2>&1]
  end
end

# check if there are files to process, if not exit
if makePNG
  cmd = "ls #{LatestDataDir}/*.png | wc -l"
else
  cmd = "ls #{LatestDataDir}/*.gif | wc -l"
end
numPlots = (%x[#{cmd}]).to_i
if 0 == numPlots
    %x[echo "No plots." >> #{PlotsDir}/#{today}.log]
    exit
end

# generate web pages
cmd = "#{ScriptsDir}/generatePages.rb"
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} > /dev/null 2>&1]
end

# move plots to plots directory
if makePNG
  cmd = "mv #{LatestDataDir}/*png #{PlotsDir}"
else
  cmd = "mv #{LatestDataDir}/*gif #{PlotsDir}"
end
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} > /dev/null 2>&1]
end

# remove data files from the latest data directory
cmd = "rm -f #{LatestDataDir}/*dat"
if dryRun
  print cmd, "\n"
else
  %x[#{cmd} > /dev/null 2>&1]
end

