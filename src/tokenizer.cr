module TextCompressor
  class Tokenizer
    getter tokens : Array(String)
    getter text : String

    def initialize(text : String)
      @text = text
      re = /\S+|\s+/
      @tokens = text.scan(re).map { |m| m[0] }
    end
  end
end
