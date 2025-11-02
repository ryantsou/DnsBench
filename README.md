# DnsBench

Bash script to benchmark public DNS servers and recommend the fastest.

## Description

DnsBench is a simple bash script that tests the response time of popular public DNS servers and helps you identify the fastest one for your network location.

## Installation

1. Clone this repository:
```bash
git clone https://github.com/ryantsou/DnsBench.git
cd DnsBench
```

2. Make the script executable:
```bash
chmod +x dns-bench.sh
```

## Usage

Run the script:
```bash
./dns-bench.sh
```

The script will test multiple DNS servers and display their response times, then recommend the fastest one.

## Examples

Example output:
```
Benchmarking DNS servers...

Google DNS (8.8.8.8): 15.2 ms
Cloudflare DNS (1.1.1.1): 12.8 ms
OpenDNS (208.67.222.222): 18.5 ms
Quad9 (9.9.9.9): 20.1 ms

Recommended DNS server: Cloudflare DNS (1.1.1.1) - 12.8 ms
```

## DNS Servers Tested

- Google DNS (8.8.8.8, 8.8.4.4)
- Cloudflare DNS (1.1.1.1, 1.0.0.1)
- OpenDNS (208.67.222.222, 208.67.220.220)
- Quad9 (9.9.9.9, 149.112.112.112)

## Author

**Riantsoa RAJHONSON**

## License

This project is licensed under the MIT License - see the LICENSE file for details.
