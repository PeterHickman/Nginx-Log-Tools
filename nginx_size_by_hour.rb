#!/usr/bin/env ruby
# encoding: UTF-8

# | date_and_hour |    count |           total |             min |             avg |             max |
# +---------------+----------+-----------------+-----------------+-----------------+-----------------+
# | 2019-09-17 06 |    15690 |      8994648617 |             246 |          573272 |          671891 |
# | 2019-09-17 07 |    32643 |     18634120480 |             293 |          570845 |          671892 |
# | 2019-09-17 08 |      216 |       123217462 |             298 |          570451 |          671891 |

require 'time'

class Note
  attr_reader :key, :count, :min, :max, :total

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

data = {}

ARGF.each do |line|
  next unless line.include?(' HTTP/1')

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

    # Include only the hour
    at   = x[pos - 4][1..14]
    size = x[pos + 2].to_f

    data[at] = Note.new(at) unless data.key?(at)

    data[at].add(size)
  rescue Exception => _
    # Oops
  end
end

format1 = '| %-13s | %8s | %15s | %15s | %15s | %15s |'
format2 = '| %-13s | %8d | %15d | %15d | %15d | %15d |'

puts format1 % %w(date_and_hour count total min avg max)
puts '+---------------+----------+-----------------+-----------------+-----------------+-----------------+'

# Create a sortable key for the data. Doing the Time.parse this late
# improves the performance by a lot

report_data = {}
data.keys.each do |k|
  begin
    nk = k.dup
    nk[11] = ' '
    nk += ':00:00'

    nk = Time.parse(nk).strftime('%Y-%m-%d %H')

    report_data[nk] = k
  rescue => e
    # It's actually cheaper to catch the error here than when parsing the line
  end
end

report_data.keys.sort.each do |k|
  x = data[report_data[k]]
  puts format2 % [k, x.count, x.total, x.min, x.average, x.max]
end
