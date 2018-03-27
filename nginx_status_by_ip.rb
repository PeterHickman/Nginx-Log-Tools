#!/usr/bin/env ruby
# encoding: UTF-8

# Parse nginx log files show the status codes by ip address
#
# | ip_address      |    count |      % |    2xx |    3xx |    4xx |    5xx |   2xx% |   3xx% |   4xx% |   5xx% |
# +-----------------+----------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
# | 10.40.247.5     |   131714 |  26.61 |  35294 |      0 |      0 |  96420 |  26.80 |   0.00 |   0.00 |  73.20 |
# | 10.40.247.7     |   217159 |  43.87 |  57432 |      0 |      0 | 159727 |  26.45 |   0.00 |   0.00 |  73.55 |
# | 84.20.195.94    |    71363 |  14.42 |  71363 |      0 |      0 |      0 | 100.00 |   0.00 |   0.00 |   0.00 |
# | 84.20.199.94    |    72802 |  14.71 |  72802 |      0 |      0 |      0 | 100.00 |   0.00 |   0.00 |   0.00 |
# | 162.13.82.178   |     1939 |   0.39 |   1939 |      0 |      0 |      0 | 100.00 |   0.00 |   0.00 |   0.00 |
# | 213.157.188.71  |       27 |   0.01 |     25 |      2 |      0 |      0 |  92.59 |   7.41 |   0.00 |   0.00 |

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
  x = text.gsub(',','').split(/\s+/)

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

  return private_ip
end

data = {}
total = 0.0

ARGF.each do |line|
  x = line.split(/\s+/)
  pos = nil
  x.each_with_index do |e, i|
    if e.include?('HTTP/1')
      pos = i
      break
    end
  end

  next unless pos

  # Include only the hour
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
  total += 1.0
end

format1 = '| %-15s | %8s | %6s | %6s | %6s | %6s | %6s | %6s | %6s | %6s | %6s |'
format2 = '| %-15s | %8d | %6.2f | %6d | %6d | %6d | %6d | %6.2f | %6.2f | %6.2f | %6.2f |'

puts format1 % %w(ip_address count % 2xx 3xx 4xx 5xx 2xx% 3xx% 4xx% 5xx%)
puts '+-----------------+----------+--------+--------+--------+--------+--------+--------+--------+--------+--------+'

report_data = {}
data.keys.each do |k|
  x = k.split('.').map{|y| y.to_i}
  z = 0
  x.each do |y|
    z = (z * 256) + y
  end

  report_data[z] = k
end

report_data.keys.sort.each do |k|
  x = data[report_data[k]]
  puts format2 % [x.key, x.count, x.count.to_f / total * 100.0, x.code2, x.code3, x.code4, x.code5, (x.code2.to_f / x.count.to_f) * 100, (x.code3.to_f / x.count.to_f) * 100, (x.code4.to_f / x.count.to_f) * 100, (x.code5.to_f / x.count.to_f) * 100]
end
