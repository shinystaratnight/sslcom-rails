module InWords
  words = %w(zero one two three four five six seven eight nine)
  words += %w(ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen)
  %w(twenty thirty fourty fifty sixty seventy eighty ninety).each { |tens| words += [tens] + words[1..9].collect { |ones| "#{tens} #{ones}" } }
  WORDS = words
  MULTIPLIERS = [[100, 'hundred'], [1000, 'thousand'], [1000000, 'million'], [1000000000, 'billion']]

  def in_words
    if self < 100
      WORDS[self]
    else
      value, text = MULTIPLIERS.reverse.detect { |value, text| self >= value }
      multiplied_value, remainder = self / value, self % value
      "#{multiplied_value.in_words} #{text}#{(remainder > 0) ? ' ' + remainder.in_words : ''}"
    end
  end
end
class Fixnum; include InWords; end
class Bignum; include InWords; end

if $0 == __FILE__ 
  require 'test/unit'
  class InWordsTest < Test::Unit::TestCase
    def test_zero_to_nine
      assert_equal 'zero'   , 0.in_words
      assert_equal 'one'    , 1.in_words
      assert_equal 'two'    , 2.in_words
      assert_equal 'three'  , 3.in_words
      assert_equal 'four'   , 4.in_words
      assert_equal 'five'   , 5.in_words
      assert_equal 'six'    , 6.in_words
      assert_equal 'seven'  , 7.in_words
      assert_equal 'eight'  , 8.in_words
      assert_equal 'nine'   , 9.in_words
    end
 
    def test_ten_to_twelve
      assert_equal 'ten'    , 10.in_words
      assert_equal 'eleven' , 11.in_words
      assert_equal 'twelve' , 12.in_words
    end
 
    def test_teens
      assert_equal 'thirteen' , 13.in_words
      assert_equal 'fourteen' , 14.in_words
      assert_equal 'fifteen'  , 15.in_words
      assert_equal 'sixteen'  , 16.in_words
      assert_equal 'seventeen', 17.in_words
      assert_equal 'eighteen' , 18.in_words
      assert_equal 'nineteen' , 19.in_words
    end
 
    def test_some_more
      assert_equal 'twenty'       , 20.in_words
      assert_equal 'seventy seven', 77.in_words
      assert_equal 'ninety nine'  , 99.in_words
    end
 
    def test_hundreds
      assert_equal 'one hundred'  , 100.in_words
      assert_equal 'three hundred', 300.in_words
      assert_equal 'seven hundred seventy seven', 777.in_words
      assert_equal 'eight hundred eighteen', 818.in_words
      assert_equal 'five hundred twelve', 512.in_words
      assert_equal 'nine hundred ninety nine', 999.in_words
    end
 
    def test_multipliers
      assert_equal 'one thousand', 1000.in_words
      assert_equal 'thirty two thousand seven hundred sixty seven', 32767.in_words
      assert_equal 'ten million one', 10000001.in_words
      assert_equal 'one billion two hundred thirty four million five hundred sixty seven thousand eight hundred ninety', 1234567890.in_words
    end
  end
end