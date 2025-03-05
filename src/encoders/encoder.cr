module TextCompressor
  ENCODER_MAP = {
    "dict" => DictionaryEncoder,
    "sym"  => SymbolEncoder,
  }

  abstract class Encoder
    abstract def encode(tokens : Array(String), threshold : Int32) : Array(String)

    abstract def decode(tokens : Array(String), encoding_keys : Array(Array(String))) : Array(String)

    abstract def encoding_keys
  end
end
