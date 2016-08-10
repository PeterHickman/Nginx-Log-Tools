#!/usr/bin/env ruby

# Parse nginx log files to list the urls being called and give various stats

class Note
  attr_reader :url, :count, :size, :time, :code2, :code3, :code4, :code5

  def initialize(url)
    @url = url

    @count = 0
    @size  = 0
    @time  = 0.0

    @code2 = 0
    @code3 = 0
    @code4 = 0
    @code5 = 0
  end

  def add(code, size, time)
    @count += 1
    @size += size
    @time += time

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

# This method allows you to munge the request path to make it less
# specific and allow stats to be collected for a class of urls. In
# this case by converting any dates into <DATE> and segments that
# are purely numeric into <NUMBER>

def munge(url)
  x = url.split('/')

  z = []

  x.each do |y|
    if y =~ /^\d\d\d\d\-\d\d-\d\d$/
      z << '<DATE>'
    elsif y =~ /^\d+$/
      z << '<NUMBER>'
    else
      z << y
    end
  end

  z.join('/')
end

# If there are any urls that you are not interested in reporting
# you can flag them as unwanted here and the program will skip them

def unwanted(url)
  ['.css', '.js', '.png', '.gif'].each do |x|
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
    # Presently we remove the query portion

    url = x[pos - 1].gsub(/\?.*/, '')
    url = munge(url)

    next if unwanted(url)

    code = x[pos + 1]
    size = x[pos + 2].to_i
    time = x[pos + 3].to_f

    data[url] = Note.new(url) unless data.has_key?(url)

    data[url].add(code, size, time)
  rescue Exception => e
    # Oops
  end
end

max_len = 0
data.values.each do |k|
  max_len = k.url.size if k.url.size > max_len
end

format1 = "| %-#{max_len}s | %8s | %12s | %12s | %6s | %6s | %6s | %6s |"
format2 = "| %-#{max_len}s | %8d | %12.3f | %12.3f | %6d | %6d | %6d | %6d |"

puts format1 % %w(request_path count avg_size avg_ms 2xx 3xx 4xx 5xx)
puts "+-#{'-' * max_len}-+----------+--------------+--------------+--------+--------+--------+--------+"

data.values.sort { |a, b| b.count <=> a.count }.each do |x|
  puts format2 % [x.url, x.count, (x.size.to_f / x.count.to_f), (x.time / x.count.to_f), x.code2, x.code3, x.code4, x.code5]
end
