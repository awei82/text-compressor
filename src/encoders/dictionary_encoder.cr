require "./encoder"

module TextCompressor
  class DictionaryEncoder < TextCompressor::Encoder
    KEY = "dict"

    getter input_tokens : Array(String) = [] of String
    getter counter : Hash(String, Int32) = Hash(String, Int32).new(0)
    getter remainder : Set(String) = Set(String).new
    # map of words to their encodings
    getter encodings : Hash(String, String) = Hash(String, String).new
    # map of encodings to their words
    getter reverse_encodings : Hash(String, String) = Hash(String, String).new
    # set of all words that caused a conflict during encoding
    # needs to be saved for reference when decoding as well
    getter conflict_words : Set(String) = Set(String).new

    @@restricted_chars = "\n\r\t\f\v #0123456789".chars

    # Returns the encoded list of tokens
    def encode(tokens : Array(String), threshold = 40) : Array(String)
      @input_tokens = tokens
      count_tokens

      eligible_words = get_eligible_words(threshold)

      # puts "Threshhold #{threshold}: #{eligible_words.size}"
      # puts eligible_words

      generate_encodings(eligible_words)
      tokens.map { |token| @encodings[token]? || token }
    end

    def decode(tokens : Array(String), encoding_keys : Array(Array(String))) : Array(String)
      words, conflict_words = encoding_keys
      @remainder = Set(String).new(conflict_words)
      generate_encodings(words)
      tokens.map { |token| @reverse_encodings[token]? || token }
    end

    # Returns a list of mappings to be appended to the compressed file.
    # The mappings are required to decode the compressed file.
    def encoding_keys() : Array(Array(String))
      return [@encodings.keys(), @conflict_words.to_a]
    end

    private def count_tokens
      @input_tokens.each do |token|
        if token.size > 2
          @counter[token] += 1
        else
          @remainder.add(token)
        end
      end
    end

    # Return the list of words that are eligible to be encoded
    # and add the rest to @remainder
    private def get_eligible_words(threshold)
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

      return eligible_words
    end

    private def encode_word(word : String, length : Int32) : String
      if length >= word.size
        return word
      elsif length < 2
        raise "Length must be greater than 1"
      elsif length == 2
        "#{word[0]}#{word.size - 1}"
      else
        "#{word[0]}#{word.size - length + 1}#{word[-(length-2)..-1]}"
      end
    end

    # This method generates the
    # @encodings, @reverse_encodings and @conflict_words
    # instance variables
    # @encodings is used to encode the file
    # @reverse_encodings is used to decode the file
    # @conflict_words is an additional mapping required to 
    # generate @reverse_encodings from the compressed file - see #decode
    # method for more details.
    private def generate_encodings(words : Array(String))
      encodings = Hash(String, Array(String)).new
      words.each do |word|
        length = 2
        encoded_word = encode_word(word, length)

        # check that the potential encodings is not one of the existing words
        while @remainder.includes?(encoded_word)
          @conflict_words.add(encoded_word)
          length += 1
          encoded_word = encode_word(word, length)
        end

        if encodings.has_key?(encoded_word)
          encodings[encoded_word] << word
        else
          encodings[encoded_word] = [word]
        end
      end

      # while duplicate mappings exist, repeat the encoding process
      # with progessively longer encodings
      duplicate_mappings = encodings.select { |k, v| v.size > 1 }
      while duplicate_mappings.size > 0
        duplicate_mappings.each do |encoded_word, words|
          new_encodings = get_reduced_encodings(words)
          encodings.delete(encoded_word)
          encodings.merge!(new_encodings)
        end

        duplicate_mappings = encodings.select { |k, v| v.size > 1 }
      end
  
      @reverse_encodings = encodings.transform_values { |v| v[0] }
      @encodings = encodings.map { |k, v| [v[0], k] }.to_h
    end

    # A helper method to find the next shortest encodings that would split the list
    private def get_reduced_encodings(words)
      counter = 1
      ptr = words[0].size - 1
      while words.map { |w| w[ptr] }.uniq.size == 1
        ptr -= 1
        counter += 1
      end
      counter += 1

      new_encodings = Hash(String, Array(String)).new
      words.each do |word|
        length = counter + 1
        encoded_word = encode_word(word, length)
        while @remainder.includes?(encoded_word)
          @conflict_words.add(encoded_word)
          length += 1
          encoded_word = encode_word(word, length)
        end

        if new_encodings.has_key?(encoded_word)
          new_encodings[encoded_word] << word
        else
          new_encodings[encoded_word] = [word]
        end
      end
      return new_encodings
    end
  end
end

