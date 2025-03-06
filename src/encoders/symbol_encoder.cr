require "./encoder"

module TextCompressor
  # Assigns a unique base64 symbol to each word selected for encoding.
  # See SymbolGenerator for symbol generation details.
  class SymbolEncoder < TextCompressor::Encoder
    @@key = "sym"

    getter counter : Hash(String, Int32) = Hash(String, Int32).new(0)
    getter remainder : Set(String) = Set(String).new
    # map of words to their encodings
    getter encodings : Hash(String, String) = Hash(String, String).new
    # map of encodings to their words
    getter reverse_encodings : Hash(String, String) = Hash(String, String).new

    @symbol_generator : SymbolGenerator = SymbolGenerator.new

    @@restricted_chars = "\n\r\t\f\v #:".chars

    def encode(tokens : Array(String), threshold : Int32 = 20) : Array(String)
      count_tokens(tokens)

      eligible_words = get_eligible_words(threshold)

      @symbol_generator = SymbolGenerator.new

      generate_encodings(eligible_words)
      tokens.map { |token| @encodings[token]? || token }
    end

    def decode(tokens : Array(String), encoding_keys : Array(Array(String))) : Array(String)
      encodings = encoding_keys.first
      @encodings = encodings.map(&.split(':')).to_h
      @reverse_encodings = @encodings.invert

      tokens.map { |token| @reverse_encodings[token]? || token }
    end

    def encoding_keys
      [@encodings.map { |k, v| "#{k}:#{v}" }]
    end

    private def count_tokens(tokens : Array(String))
      tokens.each do |token|
        if token.size > 2
          @counter[token] += 1
        else
          @remainder.add(token)
        end
      end
    end

    # Return the list of words that are eligible to be encoded
    # and add the rest to @remainder
    private def get_eligible_words(threshold : Int32 = 20)
      eligible_words = [] of String
      @counter.each do |word, count|
        if count == 1 || word.size * count < threshold
          @remainder << word
          next
        end

        if (word.chars - @@restricted_chars).size < word.size
          @remainder << word
          next
        end

        eligible_words << word
      end

      eligible_words
    end

    private def generate_encodings(words : Array(String))
      encodings = Hash(String, String).new

      words.each do |word|
        symbol = @symbol_generator.next_symbol
        while @remainder.includes?(symbol)
          symbol = @symbol_generator.next_symbol
        end

        encodings[word] = symbol
      end
      @encodings = encodings
      @reverse_encodings = encodings.invert
    end
  end

  class SymbolGenerator
    private CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".chars

    getter index : Int32

    def initialize
      @index = -1
    end

    def last_symbol
      if @index < 0
        raise "No symbols returned yet!"
      end

      get_symbol(@index)
    end

    def next_symbol
      @index += 1

      get_symbol(@index)
    end

    private def get_symbol(index)
      symbol = [] of Char
      pointer = index
      loop do
        symbol << CHARS[pointer % 64]
        pointer = pointer // 64
        break if pointer <= 0
      end
      symbol.reverse.join
    end
  end
end
