# Nginx Log Tools

Every time something crops up I find myself writing a tool to chop up the log files and 
find out what was happening. These are the more general of the tools that I have created 
over the years so I know where to find them in the future

## What data is reported

The application can report three things:

1. **`response`** The minimum, average and maximum response times for a request. Shown here by hour


		$ ngxl --report response --by hour <log files>
		
		| date_and_hour |    count |      min |      avg |      max |
		+---------------+----------+----------+----------+----------+
		| 2019-09-24 06 |    11623 |    0.006 |    0.616 |    8.219 |
		| 2019-09-24 07 |   102476 |    0.011 |    0.610 |    8.744 |
		| 2019-09-24 08 |   103262 |    0.000 |    0.609 |    8.537 |
		| 2019-09-24 09 |   103537 |    0.000 |    0.608 |    8.594 |
		| 2019-09-24 10 |   103746 |    0.000 |    0.608 |    8.969 |
		| 2019-09-24 11 |   103653 |    0.010 |    0.611 |    8.630 |
		| 2019-09-24 12 |   103392 |    0.012 |    0.612 |    9.005 |
		| 2019-09-24 13 |   103423 |    0.007 |    0.616 |    9.182 |
		| 2019-09-24 14 |   102568 |    0.000 |    0.614 |    8.781 |
		| 2019-09-24 15 |    92875 |    0.012 |    0.608 |    8.946 |

2. **`status`** A count of the status codes by class

		$ ngxl --report status --by hour <log files>
		
		| date_and_hour |    count |    2xx |    3xx |    4xx |    5xx |
		+---------------+----------+--------+--------+--------+--------+
		| 2019-09-24 06 |    11623 |  11622 |      0 |      1 |      0 |
		| 2019-09-24 07 |   102476 | 102476 |      0 |      0 |      0 |
		| 2019-09-24 08 |   103262 | 103253 |      1 |      8 |      0 |
		| 2019-09-24 09 |   103537 | 103533 |      3 |      1 |      0 |
		| 2019-09-24 10 |   103746 | 103650 |      8 |     88 |      0 |
		| 2019-09-24 11 |   103653 | 103644 |      2 |      6 |      1 |
		| 2019-09-24 12 |   103392 | 103374 |      0 |     18 |      0 |
		| 2019-09-24 13 |   103423 | 103422 |      1 |      0 |      0 |
		| 2019-09-24 14 |   102568 | 102559 |      1 |      8 |      0 |
		| 2019-09-24 15 |    92875 |  92875 |      0 |      0 |      0 |

3. **`size`** Reports the total size of all the responses along with their minimum. average and maximum

		$ ngxl --report size --by hour <log files>
		
		| date_and_hour |    count |           total |             min |             avg |             max |
		+---------------+----------+-----------------+-----------------+-----------------+-----------------+
		| 2019-09-24 06 |    11623 |        58270082 |             439 |            5013 |         1149910 |
		| 2019-09-24 07 |   102476 |       499856710 |             533 |            4877 |         1150518 |
		| 2019-09-24 08 |   103262 |       504666038 |             245 |            4887 |         1150006 |
		| 2019-09-24 09 |   103537 |       503025428 |               0 |            4858 |         1150701 |
		| 2019-09-24 10 |   103746 |       504595496 |             245 |            4863 |         1149950 |
		| 2019-09-24 11 |   103653 |       507222040 |             531 |            4893 |         1150091 |
		| 2019-09-24 12 |   103392 |       496561788 |             520 |            4802 |         1150187 |
		| 2019-09-24 13 |   103423 |       492099937 |             245 |            4758 |         1150099 |
		| 2019-09-24 14 |   102568 |       496671806 |             245 |            4842 |         1150315 |
		| 2019-09-24 15 |    92875 |       445168906 |             638 |            4793 |         1150115 |

## How the data is reported

As you can see above the data can be reported by hour. It can also be reported by ip. For example

		$ ngxl.rb --report status --by ip <log files>
		
		| ip_address      |    count |    2xx |    3xx |    4xx |    5xx |
		+-----------------+----------+--------+--------+--------+--------+
		| 10.181.201.246  |     2690 |   2690 |      0 |      0 |      0 |
		| 134.213.150.114 |      126 |    126 |      0 |      0 |      0 |
		| 134.213.56.245  |      126 |    126 |      0 |      0 |      0 |
		| 134.213.58.233  |    32935 |  32935 |      0 |      0 |      0 |
		| 141.138.130.1   |     1012 |   1012 |      0 |      0 |      0 |
		| 141.138.134.1   |     3048 |   3048 |      0 |      0 |      0 |
		| 176.58.124.134  |        1 |      0 |      0 |      1 |      0 |
		| 185.119.152.38  |     1012 |   1012 |      0 |      0 |      0 |
		| 212.22.234.47   |    24614 |  24614 |      0 |      0 |      0 |
		| 213.187.236.32  |    63553 |  63553 |      0 |      0 |      0 |
		| 220.238.156.239 |       36 |      9 |      3 |     24 |      0 |
		| 31.222.58.6     |   162026 | 162026 |      0 |      0 |      0 |
		| 34.253.163.217  |   105523 | 105523 |      0 |      0 |      0 |
		| 52.212.44.165   |     3040 |   3040 |      0 |      0 |      0 |
		| 52.215.78.102   |      648 |    648 |      0 |      0 |      0 |
		| 52.232.67.76    |        2 |      1 |      1 |      0 |      0 |
		| 52.31.67.157    |     9891 |   9891 |      0 |      0 |      0 |
		| 52.51.101.91    |      480 |    480 |      0 |      0 |      0 |
		| 54.37.17.195    |       96 |     96 |      0 |      0 |      0 |
		| 54.37.18.96     |       76 |     76 |      0 |      0 |      0 |
		| 54.37.19.80     |       70 |     70 |      0 |      0 |      0 |
		| 54.72.171.131   |    10516 |  10516 |      0 |      0 |      0 |
		| 63.34.213.250   |      125 |     21 |      0 |    104 |      0 |
		| 81.132.110.249  |      161 |    158 |      3 |      0 |      0 |
		| 85.199.212.121  |       19 |     19 |      0 |      0 |      0 |
		| 85.199.212.122  |       12 |     12 |      0 |      0 |      0 |
		| 85.199.212.123  |       18 |     18 |      0 |      0 |      0 |
		| 85.199.212.124  |       11 |     11 |      0 |      0 |      0 |
		| 85.199.212.125  |       14 |     14 |      0 |      0 |      0 |
		| 85.199.212.126  |       14 |     14 |      0 |      0 |      0 |
		| 88.151.157.235  |      151 |    140 |      9 |      1 |      1 |
		| 91.211.96.165   |   154347 | 154347 |      0 |      0 |      0 |
		| 91.211.99.90    |   161993 | 161993 |      0 |      0 |      0 |
		| 91.230.243.134  |        2 |      2 |      0 |      0 |      0 |
		| 91.230.243.135  |        1 |      1 |      0 |      0 |      0 |
		| 91.230.243.136  |        9 |      9 |      0 |      0 |      0 |
		| 91.230.243.137  |        5 |      5 |      0 |      0 |      0 |
		| 91.230.243.138  |        2 |      2 |      0 |      0 |      0 |
		| 91.230.243.139  |        2 |      2 |      0 |      0 |      0 |
		| 93.191.194.10   |   162005 | 162005 |      0 |      0 |      0 |
		| 94.125.56.56    |    30137 |  30137 |      0 |      0 |      0 |
		| 94.14.154.19    |        6 |      6 |      0 |      0 |      0 |

## Output format

By default the output is formatted as a nicely formatted text suitable from monospaced printing. If you use the `--csv` flag on the command line then the output will be formatted as csv data suitable for spreadsheets and other such tools

## Other tools

Other than the marvellous `ngxtop` (to be found at `https://github.com/lebinh/ngxtop.git`) which you should be using
if you are running Nginx there is also my other tool `https://github.com/PeterHickman/StarGraph.git` which performs
a similar task to `nginx_summary_by_hour.rb` but is written in C++ (so it's a whole lot faster) and creates a graph
which can be easier to read
