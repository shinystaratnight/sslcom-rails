#!/usr/bin/env ruby
# frozen_string_literal: true

class CSSHelper
  def initialize(file_name = nil)
    @files = file_name.nil? ? Dir['app/assets/stylesheets/**/*.*css*'] : [file_name]
  end

  def scan
    @files.each do |path|
      @file = File.open(path)
      @n = 0
      @file.each_line do |line|
        @n += 1
        match_line = line.lstrip.match(/^[.|#].*[\{]/)
        process_selectors(match_line) if match_line
      end
    end
  end

  private

  def process_selectors(line)
    selectors_all = line.to_s.split(',')
    selectors_all.each do |inner_selectors|
      selectors = inner_selectors.strip.gsub(/{$|^.|#/, '')
      selectors.split('.').each do |selector|
        stop_pos = stop_position(selector)
        match_str = selector[0..stop_pos].strip
        match = `grep -R '#{match_str}' app/views/ app/helpers/ app/assets/javascripts`
        puts "#{match_str} is unused - #{@file.path} line #{@n}" if match.empty?
      end
    end
  end

  def strip_characters(selector)
    selector = selector.lstrip
  end

  def stop_position(selector)
    index = selector.lstrip.index(/[ |:|>|)]/) || 0
    index - 1
  end
end

file = ARGV[0]
CSSHelper.new(file).scan
