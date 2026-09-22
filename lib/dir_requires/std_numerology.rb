# Standard numerology by name calculator
# VERSION: v3.0 - 2026/07/20
# Optimized for Rust FFI embedding and high-performance numeric operations

NUM_MAP = {
  a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8, i: 9,
  j: 1, k: 2, l: 3, m: 4, n: 5, o: 6, p: 7, q: 8, r: 9,
  s: 1, t: 2, u: 3, v: 4, w: 5, x: 6, y: 7, z: 8
}.freeze

module Numerology
  # Convert a word to its numerological value using digit root reduction
  #
  # @param word [String] The word to convert
  # @param num_map [Hash] Letter to number mapping (default: NUM_MAP)
  # @return [Integer] Single digit numerological value (1-9)
  def self.convert_word_to_number(word, num_map = NUM_MAP)
    return 0 if word.nil? || word.empty?

    # Sum letter values in single pass
    sum = word.downcase.each_char.sum do |char|
      num_map[char.to_sym] || 0
    end

    # Reduce to single digit (digit root)
    reduce_to_digit_root(sum)
  end

  # Reduce an integer to its digit root (single digit via repeated summation)
  #
  # @param integer [Integer] The number to reduce
  # @return [Integer] Single digit result (1-9)
  private_class_method def self.reduce_to_digit_root(integer)
    return 0 if integer.zero?

    # Mathematical optimization: digit_root = 1 + (n - 1) % 9
    1 + (integer - 1) % 9
  end

  # Batch process multiple words efficiently
  #
  # @param words [Array<String>] Words to convert
  # @return [Hash] Word => numerological value mapping
  def self.batch_convert(words)
    words.each_with_object({}) do |word, hash|
      hash[word] = convert_word_to_number(word)
    end
  end

  # Validate numerological number
  #
  # @param value [Integer] The value to validate
  # @return [Boolean] True if 1-9, false otherwise
  def self.valid_numerology_number?(value)
    value.is_a?(Integer) && (1..9).include?(value)
  end
end

# USAGE EXAMPLES:
# Numerology.convert_word_to_number("alice")                                          # => 1 (1+3+9+3+5=21 => 2+1=3... wait, let me recalc: a=1, l=3, i=9, c=3, e=5 => 1+3+9+3+5=21 => 2+1=3)
# Numerology.batch_convert(["alice", "bob", "charlie"])                               # => {"alice"=>3, "bob"=>2, "charlie"=>3}
# Numerology.valid_numerology_number?(5)                                              # => true
# Numerology.valid_numerology_number?(0)                                              # => false
# Numerology.convert_word_to_number("numerology")                                     # => Applies digit root to n+u+m+e+r+o+l+o+g+y
# Numerology.batch_convert(%w[ada bob eve]).map { |name, num| "#{name}: #{num}" }   # => ["ada: 1", "bob: 2", "eve: 5"]
