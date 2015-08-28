#!/usr/bin/ruby

# removeBadLines.rb
# Remove bad lines in the given *_dm_* file.

fileIn = ARGV[0]
fileOut = "./tempdmfile"

# open temporary file for writing
fh = File.open(fileOut, "w")

lineNum = 1         # line numbering starts from 1
numBadLines = 0
# go through the input file, line by line, and copy the good lines to the temp
# file
File.open(fileIn, "r").each_line do |line|
    matchedChars = /^#/.match(line)
    if nil == matchedChars
        # not a comment line, so proceed
        matchedChars = /^[0-9]{5}.[0-9]+,\s+[0-9]{1,4}[.]?[0-9]*,\s+[0-9]+.[0-9]+,\s+[0-9]{1,2}$/.match(line)
        if nil == matchedChars
            numBadLines += 1
        else
            # this is not a bad line, so copy
            fh << line
        end
    end
    lineNum += 1
end
print "Number of bad lines = #{numBadLines}\n"

# close temp file
fh.close

# move the temp file to the original file (replace the original file)
%x[mv -f #{fileOut} #{fileIn}]

