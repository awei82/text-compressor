require "./tokenizer"
require "./encoders/*"
require "json"
require "digest/crc32"

module TextCompressor
  # encoding_options = {
  #   "dict" => TextCompressor::DictionaryEncoder,
  #   "sym" => TextCompressor::SymbolEncoder
  # }
  extend self

  def compress(
    text : String,
    encoder_option : String = "dict",
    threshold : Int32 = 40
  ) : String
    tokens = TextCompressor::Tokenizer.new(text).tokens

    encoder = begin
      ENCODER_MAP[encoder_option].new
    rescue exception
      raise ArgumentError.new("Invalid encoder option: #{encoder_option}")
    end

    encoded_tokens = encoder.encode(tokens, threshold)
    encoded_text = encoded_tokens.join

    encoding_string = format_encoding_keys(encoder.encoding_keys)

    checksum = Digest::CRC32.checksum(encoding_string).to_s(base = 16)

    encoded_text + "\n####\n#{encoder_option} #{checksum}\n####\n#{encoding_string}"
  end

  def decompress(compressed_text : String)
    text_split = compressed_text.split("\n####\n")

    # The text is everything except the last 2 parts of the split
    text = text_split[..-3].join("\n####\n")

    meta_info = text_split[-2]
    encoding_type, checksum = meta_info.split

    encoding_string = text_split[-1]

    if Digest::CRC32.checksum(encoding_string).to_s(base = 16) != checksum
      raise "Encoding checksum does not match"
    end

    tokens = TextCompressor::Tokenizer.new(text).tokens

    encoding_keys = encoding_string.split('\n').map(&.split('#'))

    encoder = begin
      ENCODER_MAP[encoding_type].new
    rescue exception
      raise ArgumentError.new("Encoder not found: #{encoding_type}")
    end

    decoded_tokens = encoder.decode(tokens, encoding_keys)
    decoded_tokens.join
  end

  def format_encoding_keys(encoding_keys : Array(Array(String)))
    encoding_keys.map(&.join('#')).join('\n')
  end
end
