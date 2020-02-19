# frozen_string_literal: true

module Asserts
  def assert_start_with(start, str)
    assert str.start_with?(start), "Expected to start with #{start}"
  end

  def assert_false(actual)
    assert_equal(false, actual)
  end

  def assert_true(actual)
    assert_equal(false, actual)
  end
end
