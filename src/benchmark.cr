require "option_parser"

require "./text_compressor"

files = %w(
  ./samples/alice29.txt
  ./samples/asyoulik.txt
  ./samples/cp.html
  ./samples/fields.c
  ./samples/lcet10.txt
  ./samples/plrabn12.txt
  ./samples/world192.txt
  ./samples/xargs.1
)

thresholds = [20, 30, 40, 50, 60]
encoder_option = "dict"

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
    Benchmarking tool for text-compressor

    USAGE: text-compressor [OPTION] [FILE]
    Defaults to dictionary encoder - use `-e` option to select a different one.
    By default, the benchmarker will run through a sample selection of files.
    If you want to test a custom list of files, append the list at the end of the command.
    For example: `benchmark file1 file2 file3`
  BANNER

  parser.on "-e ENCODER", "--encoder=ENCODER", "Select compression encoder type (dict, sym)" do |_encoder|
    encoder_option = _encoder
  end
  parser.on "-t THSHLD", "--threshold=THSHLD", "Select a specific threshold value to test" do |_threshold|
    thresholds = [_threshold.to_i]
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.unknown_args do |_files|
    next if _files.empty?

    files = _files
  end
end

puts "Encoder: #{encoder_option}\n\n"

thresholds.each do |threshold|
  puts "**** Testing threshold: #{threshold} **** \n"
  total_size = 0
  total_compressed_size = 0
  files.each do |filename|
    puts "Testing file #{filename}..."

    text = File.open(filename) do |file|
      file.gets_to_end
    end

    total_size += text.size

    compressed_text = TextCompressor.compress(text, encoder_option, threshold)

    total_compressed_size += compressed_text.size

    compression_rate = 100 * (compressed_text.size / text.size)
    puts "Compression rate: #{compression_rate.round(1)}%"

    decompressed_text = TextCompressor.decompress(compressed_text)

    if text != decompressed_text
      raise "Decompression check failed: #{text.size} : #{decompressed_text.size}%"
    end
  end

  avg_compression_rate = 100 * (total_compressed_size / total_size)
  puts "**** Average compression rate: #{avg_compression_rate.round(1)}% 🙌 ****"
  puts ""
end
