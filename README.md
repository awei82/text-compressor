# Text Compressor

A small utility for text-based file compression

## Quickstart
```
shards build
bin/text-compressor -o output samples/alice29.txt
bin/text-compressor --decompress -o output/alice29.txt output/alice29.txt.compressed
```

## Description
The compressor is intended to be used with whitespace-separated text (see the `samples` folder for examples).

The utility come with two encoders:
- [DictionaryEncoder](src/encoders/dictionary_encoder.cr) (dict): A unique encoding is generated for words in the text
- [SymbolEncoder](src/encoders/symbol_encoder.cr) (sym): A base64 symbol generated for each encoded word in the text

### How it works
The for each encoding method, a `threshold` value is used to decide which words to encode (The algorithm is simple - it's just the # of times the word shows up * the length of the word). The threshold value can be used to tune the encoder's performance.

After the file is encoded, the encoding map is appended to the end of the file.

Create your own encoder by inheriting from the [src/encoders/encoder.cr](src/encoders/encoder.cr) file