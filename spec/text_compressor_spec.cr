require "./spec_helper"

def test_compressor(encoder_option : String, threshold, filename)
  text = File.open(filename) do |file|
    file.gets_to_end
  end
  compressed_text = TextCompressor.compress(
    text, encoder_option, threshold
  )
  
  decompressed_text = TextCompressor.decompress(compressed_text)

  decompressed_text.should eq text
end

describe TextCompressor do
  describe "dict" do
    it "encodes + decodes a file" do
      test_compressor("dict", 20, "./README.md")
      test_compressor("dict", 30, "./README.md")
      test_compressor("dict", 40, "./README.md")
    end

    it "encodes + decodes a file with #'s" do
      test_compressor("dict", 20, "./spec/pound.txt")
      test_compressor("dict", 30, "./spec/pound.txt")
      test_compressor("dict", 40, "./spec/pound.txt")
    end

    it "encodes + decodes a file with unicode characters" do
      test_compressor("dict", 20, "./spec/unicode.txt")
      test_compressor("dict", 30, "./spec/unicode.txt")
      test_compressor("dict", 40, "./spec/unicode.txt")
    end
  end
end



