#!/usr/bin/env ruby
# encoding: UTF-8

# If there are any urls that you are not interested in reporting
# you can flag them as unwanted here and the program will skip them

def unwanted(url)
  %w(.css .js .png .gif).each do |x|
    return true if url.include?(x)
  end

  false
end

threshold = ARGV[0]
if threshold =~ /^\d+$/ || threshold =~ /^\d+\.\d*$/ || threshold =~ /^\.\d+$/
  ARGV.shift
  threshold = threshold.to_f
else
  puts "The first argument should be the response threshold in seconds"
  exit(0)
end

count = 0
found = 0

ARGF.each do |line|
  next unless line.include?(' HTTP/1')

  count += 1

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

    # The response time
    time = x[pos + 3].to_f

    if time > threshold
      puts line
      found += 1
    end
  rescue Exception => e
    # Oops
  end
end

STDERR.puts "Read #{count} lines, found #{found} with response times > #{threshold}"
