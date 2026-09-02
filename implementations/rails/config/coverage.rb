# frozen_string_literal: true

require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  skip "/db/"
  minimum_coverage line: 70, branch: 40
end
