require "../spec_helper"

def test_encoder(encoder_type : TextCompressor::Encoder.class, threshold, filename)
  text = File.open(filename) do |file|
    file.gets_to_end
  end
  tokens = TextCompressor::Tokenizer.new(text).tokens

  encoder = encoder_type.new
  encoded_tokens = encoder.encode(tokens, threshold)

  deencoder = encoder_type.new
  decoded_tokens = deencoder.decode(tokens, encoder.encoding_keys)

  decoded_tokens.should eq tokens
end

describe TextCompressor::DictionaryEncoder do
  it "encodes + decodes a file" do
    test_encoder(TextCompressor::DictionaryEncoder, 20, "./README.md")
    test_encoder(TextCompressor::DictionaryEncoder, 30, "./README.md")
    test_encoder(TextCompressor::DictionaryEncoder, 40, "./README.md")
  end

  it "encodes + decodes a file with #'s" do
    test_encoder(TextCompressor::DictionaryEncoder, 20, "./spec/pound.txt")
    test_encoder(TextCompressor::DictionaryEncoder, 30, "./spec/pound.txt")
    test_encoder(TextCompressor::DictionaryEncoder, 40, "./spec/pound.txt")
  end

  it "encodes + decodes a file with unicode characters" do
    test_encoder(TextCompressor::DictionaryEncoder, 20, "./spec/unicode.txt")
    test_encoder(TextCompressor::DictionaryEncoder, 30, "./spec/unicode.txt")
    test_encoder(TextCompressor::DictionaryEncoder, 40, "./spec/unicode.txt")
  end
end



