module Dusic::AlphabetEncoding
  extend self

  ALPHABET_ENCODING_SYMBOLS = ('a'..'z').to_a + ('A'..'Z').to_a

  def alphabet_encode(int : UInt64) : String
    base : UInt64 = ALPHABET_ENCODING_SYMBOLS.size.to_u64
    str = Array(Char).new
    loop do
      new_int, pos = int.divmod(base)
      str << ALPHABET_ENCODING_SYMBOLS[pos]
      int = new_int
      break if int.zero?
    end
    str.join
  end

  def alphabet_decode(str : String) : UInt64
    # NOTE: Always operate in UInt64 to avoid arithmetic overflow
    base : UInt64 = ALPHABET_ENCODING_SYMBOLS.size.to_u64
    int : UInt64 = 0u64

    str.each_char_with_index do |ch, i|
      int += (ALPHABET_ENCODING_SYMBOLS.index(ch) || 0).to_u64 * (base ** i.to_u64)
    end
    int
  end
end
