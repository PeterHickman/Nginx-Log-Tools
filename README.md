# Nginx Log Tools

Every time something crops up I find myself writing a tool to chop up the log files and 
find out what was happening. These are the more general of the tools that I have created 
over the years so I know where to find them in the future

## Response times by hours

This, `nginx_response_by_hour.rb` takes a list of log files from the command line and and reports the total number of request per hour and report the minimum, average and maximum response times

  | date_and_hour |    count |      min |      avg |      max |
  +---------------+----------+----------+----------+----------+
  | 2017-04-03 06 |    22181 |    0.001 |    0.116 |    1.214 |
  | 2017-04-03 07 |    80224 |    0.001 |    0.162 |    2.622 |
  | 2017-04-03 08 |    74263 |    0.001 |    0.135 |    2.621 |
  | 2017-04-03 09 |    77335 |    0.001 |    0.128 |    1.776 |
  | 2017-04-03 10 |    74989 |    0.001 |    0.114 |    1.333 |
  | 2017-04-03 11 |    76663 |    0.001 |    0.133 |    1.402 |
  | 2017-04-03 12 |    73700 |    0.000 |    0.162 |    2.562 |
  | 2017-04-03 13 |    76408 |    0.001 |    0.119 |    1.258 |
  | 2017-04-03 14 |    65781 |    0.000 |    0.162 |    2.402 |

The script currently rejects urls that are for status media such as `.css`, `.js` or `.png`

## Status by hours

This, `nginx_status_by_hour.rb` takes a list of log files from the command line and and 
reports the total number of request per hour and breaks then down by response codes, `2xx`, 
`3xx`, `4xx` and `5xx`

Useful for seeing when things went south :(

	| date_and_hour |    count |    2xx |    3xx |    4xx |    5xx |
	+---------------+----------+--------+--------+--------+--------+
	| 2016-06-02 06 |     1558 |    829 |      0 |    729 |      0 |
	| 2016-06-02 07 |     3979 |   2174 |      1 |   1804 |      0 |
	| 2016-06-02 08 |     4617 |   2494 |      1 |   2122 |      0 |
	| 2016-06-02 09 |     4326 |   2347 |      2 |   1977 |      0 |
	| 2016-06-02 10 |     4158 |   2265 |      4 |   1888 |      1 |
	| 2016-06-02 11 |     4099 |   2236 |      3 |   1856 |      4 |
	| 2016-06-02 12 |     3329 |   1855 |      1 |   1473 |      0 |
	| 2016-06-02 13 |     3709 |   1892 |      0 |   1817 |      0 |

The script currently rejects urls that are for status media such as `.css`, `.js` or `.png`

## Status by ip address

This, `nginx_status_by_ip.rb`, is less useful but still occasionally required. This counts the
requests against the requesting ip address and splits them out by response codes. On occasions 
this allows us to see which ip address is having an abnormal amount of difficulty

	| ip_address      |    count |    2xx |    3xx |    4xx |    5xx |
	+-----------------+----------+--------+--------+--------+--------+
	| 1.40.124.54     |       64 |     58 |      0 |      0 |      6 |
	| 1.42.8.144      |        1 |      1 |      0 |      0 |      0 |
	| 1.42.136.244    |       22 |     22 |      0 |      0 |      0 |
	| 1.42.142.124    |      342 |    342 |      0 |      0 |      0 |
	| 1.43.77.62      |        8 |      3 |      0 |      0 |      5 |
	| 1.120.98.188    |      629 |    131 |    498 |      0 |      0 |
	| 1.120.104.129   |       13 |      8 |      0 |      0 |      5 |
	| 1.120.110.132   |       11 |      2 |      0 |      0 |      9 |
	| 1.120.138.52    |        1 |      1 |      0 |      0 |      0 |
	| 1.120.139.195   |     3125 |   3125 |      0 |      0 |      0 |
	| 1.120.143.90    |        4 |      0 |      0 |      0 |      4 |
	| 1.120.145.241   |       14 |      1 |     12 |      0 |      1 |
	| 1.120.159.31    |        2 |      0 |      0 |      0 |      2 |
	| 1.121.101.202   |        3 |      3 |      0 |      0 |      0 |
	| 1.121.102.122   |       41 |      2 |      0 |      0 |     39 |
	| 1.121.166.155   |        3 |      0 |      0 |      0 |      3 |

We are assuming that the log file format has the requesting ip address followed by any X-FORWARDED-FOR 
addresses and will only use a private ip address if there is no public ip address available

## Summary

The given log files are parsed and the request urls are munged so that `/data/line_ups/8262543` becomes
`/data/line_ups/<NUMBER>`. Additionally dates in the format `YYYY-MM-DD` will become just `<DATE>`. The
output is then sorted by total number of requests to show you the must popular urls are

	| request_path                       |    count |     avg_size |       avg_ms |    2xx |    3xx |    4xx |    5xx |
	+------------------------------------+----------+--------------+--------------+--------+--------+--------+--------+
	| /data/updates                      |   103212 |    25126.731 |        0.037 | 103190 |      0 |      0 |     22 |
	| /data/line_ups/<NUMBER>            |    86999 |      498.856 |        0.203 |  86951 |      0 |     17 |     31 |
	| /data/form/<NUMBER>/en_GB          |    34896 |     2642.953 |        0.222 |  34883 |      0 |      0 |     13 |
	| /match_detail/match_facts/<NUMBER> |    27578 |      358.919 |        0.023 |  27578 |      0 |      0 |      0 |
	| /data/table/<NUMBER>               |    17510 |     1193.618 |        0.221 |  16969 |      0 |    511 |     30 |
	| /data/form/<NUMBER>/es             |     8744 |     2749.374 |        0.148 |   8742 |      0 |      0 |      2 |
	| /data/form/<NUMBER>/it             |     3494 |     2925.114 |        0.185 |   3492 |      0 |      0 |      2 |
	| /data/live_scores                  |     3155 |      356.592 |        0.024 |   2664 |      0 |    489 |      2 |
	| /data/form/<NUMBER>/en             |     2482 |     2292.352 |        0.076 |   2470 |      0 |     12 |      0 |
	| /data/form/<NUMBER>/ru             |     1434 |     2167.534 |        0.109 |   1434 |      0 |      0 |      0 |
	| /data/form/<NUMBER>/bg             |     1213 |     2574.702 |        0.120 |   1213 |      0 |      0 |      0 |

The script currently rejects urls that are for status media such as `.css`, `.js` or `.png`. The query parameters are 
removed from the url.

## Other tools

Other than the marvellous `ngxtop` (to be found at `https://github.com/lebinh/ngxtop.git`) which you should be using
if you are running Nginx there is also my other tool `https://github.com/PeterHickman/StarGraph.git` which performs
a similar task to `nginx_summary_by_hour.rb` but is written in C++ (so it's a whole lot faster) and creates a graph
which can be easier to read
