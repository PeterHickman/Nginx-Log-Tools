#!/usr/bin/env ruby
# encoding: UTF-8

# | date_and_hour |    count |      min |      avg |      max |
# +---------------+----------+----------+----------+----------+
# | 2017-04-03 06 |    22181 |    0.001 |    0.116 |    1.214 |
# | 2017-04-03 07 |    80224 |    0.001 |    0.162 |    2.622 |
# | 2017-04-03 08 |    74263 |    0.001 |    0.135 |    2.621 |
# | 2017-04-03 09 |    77335 |    0.001 |    0.128 |    1.776 |
# | 2017-04-03 10 |    74989 |    0.001 |    0.114 |    1.333 |
# | 2017-04-03 11 |    76663 |    0.001 |    0.133 |    1.402 |
# | 2017-04-03 12 |    73700 |    0.000 |    0.162 |    2.562 |
# | 2017-04-03 13 |    76408 |    0.001 |    0.119 |    1.258 |
# | 2017-04-03 14 |    65781 |    0.000 |    0.162 |    2.402 |

require 'time'

class Note
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

# If there are any urls that you are not interested in reporting
# you can flag them as unwanted here and the program will skip them

def unwanted(url)
  %w(.css .js .png .gif).each do |x|
    return true if url.include?(x)
  end

  false
end

data = {}

ARGF.each do |line|
  begin
    x = line.split(/\s+/)
    pos = nil
    x.each_with_index do |e, i|
      if e.include?('HTTP/1')
        pos = i
        break
      end
    end

    next unless pos

    url = x[pos - 1]

    next if unwanted(url)

    # Include only the hour
    at   = x[pos - 4][1..14]
    time = x[pos + 3].to_f

    data[at] = Note.new(at) unless data.key?(at)

    data[at].add(time)
  rescue Exception => _
    # Oops
  end
end

format1 = '| %-13s | %8s | %8s | %8s | %8s |'
format2 = '| %-13s | %8d | %8.3f | %8.3f | %8.3f |'

puts format1 % %w(date_and_hour count min avg max)
puts '+---------------+----------+----------+----------+----------+'

# Create a sortable key for the data. Doing the Time.parse this late
# improves the performance by a lot

report_data = {}
data.keys.each do |k|
  nk = k.dup
  nk[11] = ' '
  nk += ':00:00'

  nk = Time.parse(nk).strftime('%Y-%m-%d %H')

  report_data[nk] = k
end

report_data.keys.sort.each do |k|
  x = data[report_data[k]]
  puts format2 % [k, x.count, x.min, x.average, x.max]
end
