# Nginx Log Tools

Every time something crops up I find myself writing a tool to chop up the log files and 
find out what was happening. These are the more general of the tools that I have created 
over the years so I know where to find them in the future

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

## Status by ip address
