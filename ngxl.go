package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"github.com/PeterHickman/toolbox"
	strftime "github.com/ncruces/go-strftime"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

type stats struct {
	count         int64
	r_sec_min     float64
	r_sec_max     float64
	r_sec_total   float64
	r_bytes_min   int64
	r_bytes_max   int64
	r_bytes_total int64
	r_code_2xx    int64
	r_code_3xx    int64
	r_code_4xx    int64
	r_code_5xx    int64
}

const by_hour string = "%Y-%m-%d %H"
const by_day string = "%Y-%m-%d"
const by_ip string = "ip"
const by_path string = "path"

var time_format string
var group_format string
var what_to_report string
var key_width string
var key_title string
var key_bar string
var csv bool

func (s *stats) update(status string, bytes int64, seconds float64) {
	s.count += 1

	if s.count == 1 {
		s.r_bytes_min = bytes
		s.r_bytes_max = bytes
		s.r_bytes_total = bytes

		s.r_sec_min = seconds
		s.r_sec_max = seconds
		s.r_sec_total = seconds
	} else {
		if bytes < s.r_bytes_min {
			s.r_bytes_min = bytes
		} else if bytes > s.r_bytes_max {
			s.r_bytes_max = bytes
		}
		s.r_bytes_total += bytes

		if seconds < s.r_sec_min {
			s.r_sec_min = seconds
		} else if seconds > s.r_sec_max {
			s.r_sec_max = seconds
		}
		s.r_sec_total += seconds
	}

	if status >= "500" {
		s.r_code_5xx += 1
	} else if status >= "400" {
		s.r_code_4xx += 1
	} else if status >= "300" {
		s.r_code_3xx += 1
	} else {
		s.r_code_2xx += 1
	}
}

func reformat(line string) []string {
	parts := strings.Fields(line)

	output := []string{}
	current_token := ""

	for _, v := range parts {
		if strings.HasPrefix(v, "\"") {
			if current_token != "" {
				output = append(output, current_token)
			}
			current_token = v
		} else if strings.HasSuffix(v, "\"") {
			current_token += fmt.Sprintf(" %s", v)
			output = append(output, current_token)
			current_token = ""
		} else if strings.HasPrefix(v, "[") {
			if current_token != "" {
				output = append(output, current_token)
			}
			current_token = v
		} else if strings.HasSuffix(v, "]") {
			current_token += fmt.Sprintf(" %s", v)
			output = append(output, current_token)
			current_token = ""
		} else {
			if strings.HasPrefix(current_token, "\"") {
				current_token += fmt.Sprintf(" %s", v)
			} else if strings.HasPrefix(current_token, "[") {
				current_token += " "
				current_token += v
			} else {
				output = append(output, v)
			}
		}

	}

	if current_token != "" {
		output = append(output, current_token)
	}

	return output
}

func http_offset(parts []string) int {
	for i, v := range parts {
		if strings.Contains(v, " HTTP") {
			return i
		}
	}

	return -1
}

func extract_date(parts []string) (string, error) {
	for _, v := range parts {
		if strings.HasPrefix(v, "[") {
			x := strings.Fields(v)
			y, err := time.Parse(time_format, x[0][1:])
			if err != nil {
				return "", err
			}
			t := strftime.Format(group_format, y)
			return t, nil
		}
	}

	return "", errors.New("Unable to locate time stamp")
}

func extract_path(path string) string {
	parts := strings.Fields(path)

	i := strings.Index(parts[1], "?")

	if i == -1 {
		return parts[1]
	} else {
		return parts[1][:i]
	}
}

func init() {
	by := flag.String("by", "", "Group data by hour|day|ip")
	re := flag.String("report", "", "What information to report status|response|size")
	c := flag.Bool("csv", false, "Output as csv")

	flag.Parse()

	b := strings.ToLower(*by)

	if b == "" {
		usage("")
	}

	switch b {
	case "day":
		group_format = by_day
		key_width = "-10"
		key_title = "day"
		key_bar = "----------"
	case "hour":
		group_format = by_hour
		key_width = "-13"
		key_title = "date_and_hour"
		key_bar = "-------------"
	case "ip":
		group_format = by_ip
		key_width = "-15"
		key_title = "ip_address"
		key_bar = "---------------"
	case "path":
		group_format = by_path
		key_width = "-15"
		key_title = "path"
		key_bar = "---------------"
	default:
		usage(fmt.Sprintf("Unrecognised --by option %s", b))
	}

	time_format, _ = strftime.Layout("%d/%b/%Y:%H:%M:%S")

	r := strings.ToLower(*re)

	if r == "" {
		usage("")
	}

	switch r {
	case "status":
		what_to_report = r
	case "response":
		what_to_report = r
	case "size":
		what_to_report = r
	default:
		usage(fmt.Sprintf("Unrecognised --report option %s", r))
	}

	csv = *c
}

func usage(message string) {
	if message != "" {
		fmt.Printf("ERROR: %s\n\n", message)
	}

	fmt.Println("ngxl --report status|size|reponse --by hour|day|ip|path [--csv] <list of Nginx log files>")
	fmt.Println()
	fmt.Println("  Will process the nginx log files and report either the status (by class),")
	fmt.Println("  size of the response in bytes (giving the total, minimum, average and maximum)")
	fmt.Println("  or response times (also with minimum, average and maximum)")
	fmt.Println()
	fmt.Println("  When grouping by path the query portion will be ignored, /fred?a=1 becomes /fred")
	fmt.Println()
	fmt.Println("  Each line of the report will be either the day or hour that the data was")
	fmt.Println("  recorded in or the ip address that the request was made from")
	fmt.Println()
	fmt.Println("  The log lines can be read from stdin if you need to pipe them (through")
	fmt.Println("  grep perhaps)")
	fmt.Println()
	fmt.Println("  The output will be formatted as CSV data if the --csv flag is given")

	os.Exit(1)
}

func process_contents(data map[string]stats, file *os.File) {
	scanner := bufio.NewScanner(file)

	var d string
	var e error

	for scanner.Scan() {
		line := scanner.Text()
		parts := reformat(line)
		http := http_offset(parts)

		if http != -1 {
			if group_format == by_ip {
				d = parts[0]
				e = nil
			} else if group_format == by_path {
				d = extract_path(parts[http])
				e = nil
			} else {
				d, e = extract_date(parts)
			}

			if e == nil {
				val, ok := data[d]

				if !ok {
					data[d] = stats{}
				}

				// Status code for the response
				status := parts[http+1]

				// Size of response in bytes
				bytes, _ := strconv.ParseInt(parts[http+2], 10, 64)

				// Response time in seconds
				seconds, _ := strconv.ParseFloat(parts[http+3], 64)

				val.update(status, bytes, seconds)
				data[d] = val
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}

func process_file(data map[string]stats, filename string) {
	if !toolbox.FileExists(filename) {
		log.Fatalf("Cannot find logfile %s", filename)
	}

	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}

	process_contents(data, file)

	file.Close()
}

func report(data map[string]stats) {
	keys := make([]string, 0, len(data))

	max_width := 0

	for k := range data {
		l := len(k)

		if l > max_width {
			max_width = l
		}

		keys = append(keys, k)
	}

	if group_format == by_path {
		key_width = fmt.Sprintf("-%d", max_width)
		key_bar = strings.Repeat("-", max_width)
	}

	sort.Strings(keys)

	var format string

	switch what_to_report {
	case "response":
		fmt.Printf("| %"+key_width+"s |    count |      min |      avg |      max |\n", key_title)
		fmt.Println("+-" + key_bar + "-+----------+----------+----------+----------+")
		format = "| %" + key_width + "s | %8d | %8.3f | %8.3f | %8.3f |\n"
	case "status":
		fmt.Printf("| %"+key_width+"s |    count |      2xx |      3xx |      4xx |      5xx |\n", key_title)
		fmt.Println("+-" + key_bar + "-+----------+----------+----------+----------+----------+")
		format = "| %" + key_width + "s | %8d | %8d | %8d | %8d | %8d |\n"
	case "size":
		fmt.Printf("| %"+key_width+"s |    count |           total |             min |             avg |             max |\n", key_title)
		fmt.Println("+-" + key_bar + "-+----------+-----------------+-----------------+-----------------+-----------------+")
		format = "| %" + key_width + "s | %8d | %15d | %15d | %15d | %15d |\n"
	}

	for _, k := range keys {
		v := data[k]

		switch what_to_report {
		case "response":
			fmt.Printf(format, k, v.count, v.r_sec_min, (v.r_sec_total / float64(v.count)), v.r_sec_max)
		case "status":
			fmt.Printf(format, k, v.count, v.r_code_2xx, v.r_code_3xx, v.r_code_4xx, v.r_code_5xx)
		case "size":
			fmt.Printf(format, k, v.count, v.r_bytes_total, v.r_bytes_min, v.r_bytes_total/v.count, v.r_bytes_max)
		}
	}
}

func report_csv(data map[string]stats) {
	keys := make([]string, 0, len(data))

	for k := range data {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	switch what_to_report {
	case "response":
		fmt.Printf("%s,%s,%s,%s,%s\n", key_title, "count", "min", "avg", "max")
	case "status":
		fmt.Printf("%s,%s,%s,%s,%s,%s\n", key_title, "count", "2xx", "3xx", "4xx", "5xx")
	case "size":
		fmt.Printf("%s,%s,%s,%s,%s,%s\n", key_title, "count", "total", "min", "avg", "max")
	}

	for _, k := range keys {
		v := data[k]
		switch what_to_report {
		case "response":
			fmt.Printf("%s,%d,%.3f,%.3f,%.3f\n", k, v.count, v.r_sec_min, (v.r_sec_total / float64(v.count)), v.r_sec_max)
		case "status":
			fmt.Printf("%s,%d,%d,%d,%d,%d\n", k, v.count, v.r_code_2xx, v.r_code_3xx, v.r_code_4xx, v.r_code_5xx)
		case "size":
			fmt.Printf("%s,%d,%d,%d,%d,%d\n", k, v.count, v.r_bytes_total, v.r_bytes_min, v.r_bytes_total/v.count, v.r_bytes_max)
		}
	}
}

func main() {
	data := map[string]stats{}

	if len(flag.Args()) > 0 {
		for _, filename := range flag.Args() {
			process_file(data, filename)
		}
	} else {
		process_contents(data, os.Stdin)
	}

	if csv {
		report_csv(data)
	} else {
		report(data)
	}
}
