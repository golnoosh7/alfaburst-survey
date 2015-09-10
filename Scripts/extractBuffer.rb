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
TempHeaderFile = "/data/Survey/Tmp/tempheader.fil"
TempDataFile = "/data/Survey/Tmp/tempdata.fil"
NumSamples = 32768
NumChans = 512
NumBytesPerSample = 4
BufferBytes = NumSamples * NumChans * NumBytesPerSample

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

# run yapp_viewmetadata to get the header size
headerBytes = (%x[yapp_viewmetadata #{fileData} | tail -1 | cut -d ":" -f 2 | sed -e "s/^[ ]//"]).to_i
puts headerBytes

# run dd to copy the header to a temp file
puts "dd if=#{fileData} of=#{TempHeaderFile} bs=#{headerBytes} count=1"
#%x[dd if=#{fileData} of=#{TempHeaderFile} bs=#{headerBytes} count=1]

# run dd to copy the data to a temp file
dataBytes = (buffer - 1) * BufferBytes
puts "dd if=#{fileData} of=#{TempDataFile} bs=1 count=#{dataBytes} skip=#{headerBytes}"
#%x[dd if=#{fileData} of=#{TempDataFile} bs=1 count=#{dataBytes} skip=#{headerBytes}]

# build output file name
# get file name without extension
basename = File.basename(fileData, ".fil")
# get directory in which file exists
dirname = File.dirname(fileData)
# build file name
fileBuffer = dirname + basename + ".buffer#{buffer}.fil"

# combine the temp header and data files
puts "cat #{TempHeaderFile} #{TempDataFile} > #{fileBuffer}"
#%x[cat #{TempHeaderFile} #{TempDataFile} > #{fileBuffer}]

