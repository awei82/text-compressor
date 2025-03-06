require "./text_compressor"
require "option_parser"

filename = ""

action = :compress
encoder_option = "dict"
threshold = 0
output_path = ""
custom_output_path = ""

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
    Text file compressor

    USAGE: text-compressor [OPTION] FILE
    By default, the utility will compress the target file. To decompress, use the `-d` option.

  BANNER

  parser.on "-d", "--decompress", "Decompresses a compressed text file" do
    action = :decompress
    # output_path = "#{Path[filename].basename}.decompressed"
  end

  parser.on "-e ENCODER", "--encoder=ENCODER", "Select compression encoder type (dict, sym)" do |_encoder|
    encoder_option = _encoder
  end
  parser.on "-t THSHLD", "--threshold=THSHLD", "Select compression threshold value" do |_threshold|
    threshold = _threshold.to_i
  end
  parser.on "-o OUTPUT_PATH", "--output=OUTPUT_PATH", "Select output file or path location" do |_output_path|
    custom_output_path = _output_path
    # See `parser.unknown_args` section for custom output path handling.
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  # Handle filename parsing + output filename selection
  parser.unknown_args do |args|
    if args.empty?
      puts "Error: missing file to compress"
      exit
    elsif args.size > 1
      puts "Error: only pass in one filname"
      exit
    elsif args.size == 1
      filename = args.first

      if action == :compress
        output_path = "#{Path[filename].basename}.compressed"
      else
        output_path = "#{Path[filename].basename}.decompressed"
      end

      if custom_output_path
        # if custom out path is a directory, save the file in the directory
        if Dir.exists? custom_output_path.as(String)
          output_path = "#{custom_output_path}/#{output_path}"
        else
          output_path = custom_output_path
        end
      end
    end
  end
end

# configure default threshold value if none given.
if threshold == 0
  threshold = if encoder_option == "symbol"
                20
              else
                40
              end
end

if action == :compress
  text = File.open(filename) do |file|
    file.gets_to_end
  end

  compressed_text = TextCompressor.compress(text, encoder_option, threshold)

  File.open(output_path, "w") do |file|
    file << compressed_text
  end

  puts "Original file size: #{File.size(filename)} bytes"
  puts "Compressed file size: #{File.size(output_path)} bytes"
  compression_rate = 100 * (File.size(output_path) / File.size(filename))
  puts "Compression rate: #{(compression_rate).round(1)}%"

  puts "Compressed file saved to #{output_path}"
else
  compressed_text = File.open(filename) do |file|
    file.gets_to_end
  end

  decompressed_text = TextCompressor.decompress(compressed_text)

  File.open(output_path, "w") do |file|
    file << decompressed_text
  end
  puts "Decompressed file saved to #{output_path}"
end
