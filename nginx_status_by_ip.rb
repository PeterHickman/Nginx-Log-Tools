#!/usr/bin/env ruby
# encoding: UTF-8

# Parse nginx log files show the status codes by ip address
#
# | ip_address      |    count |    2xx |    3xx |    4xx |    5xx |
# +-----------------+----------+--------+--------+--------+--------+
# | 1.40.124.54     |       64 |     58 |      0 |      0 |      6 |
# | 1.42.8.144      |        1 |      1 |      0 |      0 |      0 |
# | 1.42.136.244    |       22 |     22 |      0 |      0 |      0 |
# | 1.42.142.124    |      342 |    342 |      0 |      0 |      0 |
# | 1.43.77.62      |        8 |      3 |      0 |      0 |      5 |
# | 1.120.98.188    |      629 |    131 |    498 |      0 |      0 |
# | 1.120.104.129   |       13 |      8 |      0 |      0 |      5 |
# | 1.120.110.132   |       11 |      2 |      0 |      0 |      9 |
# | 1.120.138.52    |        1 |      1 |      0 |      0 |      0 |
# | 1.120.139.195   |     3125 |   3125 |      0 |      0 |      0 |
# | 1.120.143.90    |        4 |      0 |      0 |      0 |      4 |
# | 1.120.145.241   |       14 |      1 |     12 |      0 |      1 |
# | 1.120.159.31    |        2 |      0 |      0 |      0 |      2 |
# | 1.121.101.202   |        3 |      3 |      0 |      0 |      0 |
# | 1.121.102.122   |       41 |      2 |      0 |      0 |     39 |
# | 1.121.166.155   |        3 |      0 |      0 |      0 |      3 |

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

def get_ip(text)
  x = text.delete(',').split(/\s+/)

  private_ip = '0.0.0.0'

  x.each do |ip|
    if ip == '127.0.0.1'
      # Ignore
    elsif ip.index('10.') == 0 || ip.index('192.168.')
      private_ip = ip
    else
      return ip
    end
  end

  private_ip
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

    code = x[pos + 1]

    pos = nil
    x.each_with_index do |e, i|
      if e.index('[') == 0
        pos = i
        break
      end
    end

    ip = get_ip(x[0...pos].join(' '))

    data[ip] = Note.new(ip) unless data.key?(ip)

    data[ip].add(code)
  rescue Exception => _
    # Oops
  end
end

format1 = '| %-15s | %8s | %6s | %6s | %6s | %6s |'
format2 = '| %-15s | %8d | %6d | %6d | %6d | %6d |'

puts format1 % %w(ip_address count 2xx 3xx 4xx 5xx)
puts '+-----------------+----------+--------+--------+--------+--------+'

report_data = {}
data.keys.each do |k|
  x = k.split('.').map(&:to_i)
  z = 0
  x.each do |y|
    z = (z * 256) + y
  end

  report_data[z] = k
end

report_data.keys.sort.each do |k|
  x = data[report_data[k]]
  puts format2 % [x.key, x.count, x.code2, x.code3, x.code4, x.code5]
end
