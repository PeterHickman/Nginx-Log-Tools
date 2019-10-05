#!/usr/bin/env ruby
# encoding: UTF-8

require 'time'

class MinimumAverageMaximum
  attr_reader :key, :count, :min, :max, :total

  def initialize
    @count = 0.0

    @total = 0.0
    @min   = 0.0
    @max   = 0.0
  end

  def add(value)
    value = value.to_f

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

  def initialize
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

REPORT_VALUES = {
  'status'   => { 'offset' => 1, 'class' => Statuses },
  'size'     => { 'offset' => 2, 'class' => MinimumAverageMaximum },
  'response' => { 'offset' => 3, 'class' => MinimumAverageMaximum }
}.freeze

BY_VALUES = %w[hour ip].freeze

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
  raise "Argument to #{REPORT} must be one of '#{REPORT_VALUES.keys.join("', '")}'" unless REPORT_VALUES.key?(options[REPORT])

  raise "Missing option #{BY}" unless options.key?(BY)
  raise "Argument to #{BY} must be one of '#{BY_VALUES.keys.join("', '")}'" unless BY_VALUES.include?(options[BY])

  return unless options.size > 2

  x = options.keys
  x.delete(REPORT)
  x.delete(BY)

  raise "Unknown option(s) #{x.inspect}"
end

def process_line_from_file(fh, data, by, report_values)
  fh.each do |line|
    parts = line.split(/\s+/)
    pos = nil
    i = 0

    parts.each do |e|
      if e.include?('HTTP/1')
        pos = i
        break
      end
      i += 1
    end

    next unless pos

    k = by == 'ip' ? parts[0] : parts[pos - 4][1..14]

    data[k] = report_values['class'].new unless data.key?(k)
    data[k].add(parts[pos + report_values['offset']])
  end
end

def format_date(date)
  nk = date.dup
  nk[11] = ' '
  nk += ':00:00'

  Time.parse(nk).strftime('%Y-%m-%d %H')
rescue
end

def setup_display(by, report)
  header = []
  line = []

  case by
  when 'hour'
    header << '%-13s' % 'date_and_hour'
    line << '%-13s'
  when 'ip'
    header << '%-15s' % 'ip_address'
    line << '%-15s'
  end

  case report
  when 'status'
    header << '%8s' % 'count'
    header << '%6s' % '2xx'
    header << '%6s' % '3xx'
    header << '%6s' % '4xx'
    header << '%6s' % '5xx'

    line += ['%8d', '%6d', '%6d', '%6d', '%6d']
  when 'size'
    header << '%8s' % 'count'
    header << '%15s' % 'total'
    header << '%15s' % 'min'
    header << '%15s' % 'avg'
    header << '%15s' % 'max'

    line += ['%8d', '%15d', '%15d', '%15d', '%15d']
  when 'response'
    header << '%8s' % 'count'
    header << '%8s' % 'min'
    header << '%8s' % 'avg'
    header << '%8s' % 'max'

    line += ['%8d', '%8.3f', '%8.3f', '%8.3f']
  end

  [header, line]
end

def sorted_keys(by, keys)
  x = {}

  case by
  when 'hour'
    keys.each do |k|
      y = format_date(k)
      next unless y

      x[y] = k
    end
  when 'ip'
    keys.each do |k|
      x[k] = k
    end
  end

  x
end

options, arguments = opts

valid_options(options)

report = options[REPORT]
by     = options[BY]

data = {}

if arguments.any?
  arguments.each do |filename|
    fh = File.open(filename, 'r')
    process_line_from_file(fh, data, by, REPORT_VALUES[report])
    fh.close
  end
else
  process_line_from_file(STDIN, data, by, REPORT_VALUES[report])
end

header, line = setup_display(by, report)

puts "| #{header.join(' | ')} |"
puts "+-#{header.map { |i| '-' * i.size }.join('-+-')}-+"

x = "| #{line.join(' | ')} |"

sk = sorted_keys(by, data.keys)

sk.keys.sort.each do |k|
  v = data[sk[k]]

  case report
  when 'status'
    puts x % [k, v.count, v.code2, v.code3, v.code4, v.code5]
  when 'size'
    puts x % [k, v.count, v.total, v.min, v.average, v.max]
  when 'response'
    puts x % [k, v.count, v.min, v.average, v.max]
  end
end
