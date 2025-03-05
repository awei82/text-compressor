require "./text_compressor"
require "option_parser"

filename = ARGV[-1]

action = :compress
encoder_option = "dict"
threshold = 0
output_path = "#{Path[filename].basename}.compressed"

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
    Text file compressor

    USAGE: text-compressor [OPTION] [FILE]
    By default, the utility will compress the target file. To decompress, use the `-d` option.

  BANNER

  parser.on "-d", "--decompress", "Decompresses a compressed text file" do
    action = :decompress
    output_path = "#{Path[filename].basename}.decompressed"
  end

  parser.on "-e ENCODER", "--encoder=ENCODER", "Select compression encoder type (dict, sym)" do |_encoder|
    encoder_option = _encoder
  end
  parser.on "-t THSHLD", "--threshold=THSHLD", "Select compression threshold value" do |_threshold|
    threshold = _threshold.to_i
  end
  parser.on "-o OUTPUT_PATH", "--output=OUTPUT_PATH", "Select output file or path location" do |_output_path|
    if Dir.exists? _output_path
      output_path = _output_path + "/" + output_path
    else
      output_path = _output_path
    end
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
end

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
    file.puts compressed_text
  end

  puts "Original file size: #{File.size(filename)} bytes / #{text.size}"
  puts "Compressed file size: #{File.size(output_path)} bytes / #{compressed_text.size}"
  compression_rate = 100 * (File.size(output_path) / File.size(filename))
  puts "Compression rate: #{(compression_rate).round(2)}%"

  puts "Compressed file saved to #{output_path}"
else
  compressed_text = File.open(filename) do |file|
    file.gets_to_end
  end

  decompressed_text = TextCompressor.decompress(compressed_text)

  File.open(output_path, "w") do |file|
    file.puts decompressed_text
  end
  puts "Decompressed file saved to #{output_path}"
end
