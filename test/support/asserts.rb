# frozen_string_literal: true

module Asserts
  def assert_start_with(start, str)
    assert str.start_with?(start), "Expected to start with #{start}"
  end
end
