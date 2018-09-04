#!/usr/bin/env ruby
# encoding: UTF-8

# Parse nginx log files show the status codes by hour
#
# | date_and_hour |    count |    2xx |    3xx |    4xx |    5xx |
# +---------------+----------+--------+--------+--------+--------+
# | 2016-06-02 06 |     1558 |    829 |      0 |    729 |      0 |
# | 2016-06-02 07 |     3979 |   2174 |      1 |   1804 |      0 |
# | 2016-06-02 08 |     4617 |   2494 |      1 |   2122 |      0 |
# | 2016-06-02 09 |     4326 |   2347 |      2 |   1977 |      0 |
# | 2016-06-02 10 |     4158 |   2265 |      4 |   1888 |      1 |
# | 2016-06-02 11 |     4099 |   2236 |      3 |   1856 |      4 |
# | 2016-06-02 12 |     3329 |   1855 |      1 |   1473 |      0 |
# | 2016-06-02 13 |     3709 |   1892 |      0 |   1817 |      0 |

require 'time'

class Note
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

    next if unwanted(url)

    # Include only the hour
    at   = x[pos - 4][1..14]
    code = x[pos + 1]

    data[at] = Note.new(at) unless data.key?(at)

    data[at].add(code)
  rescue Exception => _
    # Oops
  end
end

format1 = '| %-13s | %8s | %6s | %6s | %6s | %6s |'
format2 = '| %-13s | %8d | %6d | %6d | %6d | %6d |'

puts format1 % %w(date_and_hour count 2xx 3xx 4xx 5xx)
puts '+---------------+----------+--------+--------+--------+--------+'

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
  puts format2 % [k, x.count, x.code2, x.code3, x.code4, x.code5]
end
