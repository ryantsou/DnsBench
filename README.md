# DnsBench

Bash script to benchmark public DNS resolvers and recommend the fastest one from your current network.

## What it does

DnsBench measures recursive DNS lookup latency against several public resolvers, across multiple domains, and ranks the servers by observed average response time. It is more useful than a single-query demo because it shows average, min, max, and success coverage for each server.

## Requirements

- Bash 4+
- `dig`
- `awk`
- `sort`

## Installation

1. Clone this repository:
```bash
git clone https://github.com/ryantsou/dns-bench.git
cd dns-bench
```

2. Make the script executable:
```bash
chmod +x dns-bench.sh
```

## Usage

Run the benchmark with the defaults:
```bash
./dns-bench.sh
```

Override the test domains, query count, and timeout:
```bash
./dns-bench.sh -d google.com,cloudflare.com,github.com -n 7 -t 3
```

Options:

- `-d` Comma-separated list of domains to test.
- `-n` Queries per domain and DNS server.
- `-t` Timeout in seconds for each lookup.

## Output

The script prints one line per resolver with:

- average latency in ms
- number of successful queries
- observed min/max latency
- a ranked summary and recommendation

## Notes for engineers

- This benchmarks resolver latency from the current machine, not global DNS quality.
- Results can change based on cache state, peering, geography, and transient upstream load.
- For production changes, rerun the benchmark from the target network and at different times of day.

## DNS servers tested

- Google DNS (8.8.8.8, 8.8.4.4)
- Cloudflare DNS (1.1.1.1, 1.0.0.1)
- OpenDNS (208.67.222.222, 208.67.220.220)
- Quad9 (9.9.9.9, 149.112.112.112)

## Author

Riantsoa RAJHONSON

## License

This project is licensed under the MIT License - see the LICENSE file for details.
