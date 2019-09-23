#!/usr/bin/env ruby
# encoding: UTF-8

require 'time'

class MinimumAverageMaximum
  attr_reader :key, :count, :min, :max

  def initialize(key)
    @key = key

    @count = 0.0

    @total = 0.0
    @min   = 0.0
    @max   = 0.0
  end

  def add(value)
    if @count == 0.0
      @min = value
      @max = value
    else
      @min = value if value < @min
      @max = value if value > @max
    end

    @count += 1.0
    @total += value
  end

  def average
    @total / @count
  end
end

class Statuses
  attr_reader :key, :count, :code2, :code3, :code4, :code5

  def initialize(key)
    @key = key

    @count = 0

    @code2 = 0
    @code3 = 0
    @code4 = 0
    @code5 = 0
  end

  def add(code)
    @count += 1

    case code[0..0]
    when '2'
      @code2 += 1
    when '3'
      @code3 += 1
    when '4'
      @code4 += 1
    when '5'
      @code5 += 1
    end
  end
end

REPORT = '--report'.freeze
BY     = '--by'.freeze

REPORT_VALUES = %w(status size response).freeze
BY_VALUES     = %w(hour ip).freeze

def opts
  ##
  # Assumes that the options, in long format such as "--file xxx",
  # will come before the arguments. The first argument that appears
  # will signal the end of the options. So with:
  #
  # --file fred.txt --delim tab arnold smith --output fred.out
  #
  # "--file" and "--delim" are options and "arnold", "smith",
  # "--output", "fred.out" are all arguments
  #
  # To force option like arguments from being read as options
  # the plain "--" option will stop looking for options. Everything
  # after the "--" will be arguments
  #
  # All options must have parameters
  #
  # Probably a tad over-engineered :)
  ##

  commands = ARGV.dup

  options = {}
  arguments = []

  end_of_options = false

  while commands.any?
    x = commands.shift.downcase

    if end_of_options
      arguments << x
    elsif x == '--'
      end_of_options = true
    elsif x.index('--') == 0
      y = commands.shift.downcase
      options[x] = y
    else
      arguments << x
      end_of_options = true
    end
  end

  [options, arguments]
end

def valid_options(options)
  raise "Missing option #{REPORT}" unless options.key?(REPORT)
  raise "Argument to #{REPORT} must be either 'status', 'size' or 'response'" unless REPORT_VALUES.include?(options[REPORT])

  raise "Missing option #{BY}" unless options.key?(BY)
  raise "Argument to #{BY} must be either 'hour' or 'ip'" unless BY_VALUES.include?(options[BY])

  if options.size > 2
    x = options.keys
    x.delete(REPORT)
    x.delete(BY)

    raise "Unknown option(s) #{x.inspect}"
  end
end

def process_line(line)
  puts line.upcase
end

options, arguments = opts

valid_options(options)

report = options[REPORT]
by     = options[BY]

if arguments.any?
  arguments.each do |filename|
    File.open(filename, 'r').each do |line|
      process_line(line)
    end
  end
else
  STDIN.read.split("\n").each do |line|
    process_line(line)
  end
end
