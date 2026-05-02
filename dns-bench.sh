#!/bin/bash

################################################################################
# DNS Benchmark Script
#
# Description:
#   This script tests the response time of popular public DNS servers by
#   performing DNS lookups and measuring latency. It then ranks the servers
#   by performance and recommends the fastest one.
#
# Author: Riantsoa RAJHONSON
# License: MIT License
#
# Usage:
#   chmod +x dns-bench.sh
#   ./dns-bench.sh
################################################################################

# Color codes for output formatting
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Array of DNS servers to test
# Format: "Name|IP"
declare -a DNS_SERVERS=(
    "Google DNS Primary|8.8.8.8"
    "Google DNS Secondary|8.8.4.4"
    "Cloudflare DNS Primary|1.1.1.1"
    "Cloudflare DNS Secondary|1.0.0.1"
    "OpenDNS Primary|208.67.222.222"
    "OpenDNS Secondary|208.67.220.220"
    "Quad9 Primary|9.9.9.9"
    "Quad9 Secondary|149.112.112.112"
)

# Default test domains for DNS lookups
declare -a DEFAULT_TEST_DOMAINS=(
    "google.com"
    "cloudflare.com"
    "github.com"
    "microsoft.com"
)

declare -a TEST_DOMAINS=("${DEFAULT_TEST_DOMAINS[@]}")

# Number of queries per domain and DNS server
QUERY_COUNT=5

# Timeout passed to dig, in seconds
TIMEOUT=2

################################################################################
# Function: check_dependencies
# Description: Verifies that required commands are available
################################################################################
check_dependencies() {
    local missing_deps=()

    for cmd in dig awk sort; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install them before running this script."
        exit 1
    fi
}

################################################################################
# Function: usage
# Description: Prints the command line usage
################################################################################
usage() {
    cat <<EOF
Usage: $0 [-d domains] [-n count] [-t timeout] [-h]

Options:
  -d domains   Comma-separated list of domains to test.
  -n count     Queries per domain and DNS server (default: $QUERY_COUNT).
  -t timeout   dig timeout in seconds (default: $TIMEOUT).
  -h           Show this help message.

Examples:
  $0
  $0 -d google.com,cloudflare.com,github.com -n 7 -t 3
EOF
}

################################################################################
# Function: parse_args
# Description: Reads CLI overrides for domains and benchmark settings
################################################################################
parse_args() {
    local custom_domains=()
    local raw_domains=()
    local domain

    while getopts ":d:n:t:h" opt; do
        case "$opt" in
            d)
                IFS=',' read -r -a raw_domains <<< "$OPTARG"
                for domain in "${raw_domains[@]}"; do
                    domain="${domain//[[:space:]]/}"
                    if [ -n "$domain" ]; then
                        custom_domains+=("$domain")
                    fi
                done
                ;;
            n)
                QUERY_COUNT="$OPTARG"
                ;;
            t)
                TIMEOUT="$OPTARG"
                ;;
            h)
                usage
                exit 0
                ;;
            :)
                echo -e "${RED}Error: Option -$OPTARG requires an argument.${NC}"
                usage
                exit 1
                ;;
            \?)
                echo -e "${RED}Error: Unknown option -$OPTARG.${NC}"
                usage
                exit 1
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [ $# -gt 0 ]; then
        echo -e "${RED}Error: unexpected positional arguments: $*.${NC}"
        usage
        exit 1
    fi

    if [ ${#custom_domains[@]} -gt 0 ]; then
        TEST_DOMAINS=("${custom_domains[@]}")
    fi
}

################################################################################
# Function: validate_inputs
# Description: Validates benchmark parameters
################################################################################
validate_inputs() {
    if ! [[ "$QUERY_COUNT" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}Error: query count must be a positive integer.${NC}"
        exit 1
    fi

    if ! [[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}Error: timeout must be a positive integer.${NC}"
        exit 1
    fi

    if [ ${#TEST_DOMAINS[@]} -eq 0 ]; then
        echo -e "${RED}Error: at least one test domain is required.${NC}"
        exit 1
    fi
}

################################################################################
# Function: test_dns_server
# Description: Tests a single DNS server and returns average response time
# Parameters:
#   $1 - DNS server IP address
# Returns: Average response time in milliseconds
################################################################################
test_dns_server() {
    local dns_ip=$1
    local total_time=0
    local successful_queries=0
    local min_time=""
    local max_time=""
    local domain
    local i
    local query_time

    for domain in "${TEST_DOMAINS[@]}"; do
        for ((i = 1; i <= QUERY_COUNT; i++)); do
            query_time=$(dig @"${dns_ip}" "$domain" +timeout="$TIMEOUT" +tries=1 +stats 2>&1 | awk '/Query time:/ {print $4; exit}')

            if [[ "$query_time" =~ ^[0-9]+$ ]]; then
                total_time=$((total_time + query_time))
                ((successful_queries++))

                if [ -z "$min_time" ] || [ "$query_time" -lt "$min_time" ]; then
                    min_time="$query_time"
                fi

                if [ -z "$max_time" ] || [ "$query_time" -gt "$max_time" ]; then
                    max_time="$query_time"
                fi
            fi
        done
    done

    if [ $successful_queries -eq 0 ]; then
        echo "timeout"
    else
        local avg_time
        avg_time=$(awk -v total="$total_time" -v count="$successful_queries" 'BEGIN { printf "%.2f", total / count }')
        echo "$avg_time|$successful_queries|$min_time|$max_time"
    fi
}

################################################################################
# Function: format_time
# Description: Formats time value for display
# Parameters:
#   $1 - Time value
################################################################################
format_time() {
    local time=$1
    if [ "$time" = "timeout" ]; then
        echo "${RED}TIMEOUT${NC}"
    else
        echo "${GREEN}${time} ms${NC}"
    fi
}

################################################################################
# Main Script
################################################################################

parse_args "$@"
validate_inputs

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   DNS Server Benchmark Tool${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check dependencies
check_dependencies

echo -e "Testing domains: ${YELLOW}${TEST_DOMAINS[*]}${NC}"
echo -e "Queries per domain and server: ${YELLOW}${QUERY_COUNT}${NC}"
echo -e "Timeout: ${YELLOW}${TIMEOUT}s${NC}"
echo ""
echo -e "${BLUE}Benchmarking DNS servers...${NC}"
echo ""

declare -a valid_servers

# Test each DNS server
for server_info in "${DNS_SERVERS[@]}"; do
    IFS='|' read -r name ip <<< "$server_info"
    
    echo -n "Testing $name ($ip)... "
    
    avg_time=$(test_dns_server "$ip")
    if [ "$avg_time" = "timeout" ]; then
        echo -e "${RED}TIMEOUT${NC}"
    else
        IFS='|' read -r avg_value success_count min_value max_value <<< "$avg_time"
        valid_servers+=("$name|$ip|$avg_value|$success_count|$min_value|$max_value")
        echo -e "$(format_time "$avg_value") (${success_count}/${#TEST_DOMAINS[@]} domains x $QUERY_COUNT queries, ${min_value}-${max_value} ms)"
    fi
done

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   Results Summary${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Sort valid servers by response time
if [ ${#valid_servers[@]} -eq 0 ]; then
    echo -e "${RED}No DNS servers responded successfully.${NC}"
    exit 1
fi

mapfile -t sorted_servers < <(printf '%s\n' "${valid_servers[@]}" | sort -t'|' -k3,3n)

echo -e "${YELLOW}Ranked DNS Servers (fastest to slowest):${NC}"
echo ""

rank=1
for server_data in "${sorted_servers[@]}"; do
    IFS='|' read -r name ip time success_count min_time max_time <<< "$server_data"
    echo -e "${rank}. $name ($ip): ${GREEN}${time} ms${NC} (${success_count}/${#TEST_DOMAINS[@]} domains x $QUERY_COUNT, ${min_time}-${max_time} ms)"
    ((rank++))
done

echo ""
echo -e "${BLUE}=====================================${NC}"

# Recommend the fastest server
IFS='|' read -r best_name best_ip best_time best_success_count best_min_time best_max_time <<< "${sorted_servers[0]}"
echo -e "${GREEN}✓ Recommended DNS Server:${NC}"
echo -e "  ${YELLOW}${best_name}${NC} (${best_ip})"
echo -e "  Average response time: ${GREEN}${best_time} ms${NC}"
echo -e "  Observations: ${best_success_count}/${#TEST_DOMAINS[@]} domains x $QUERY_COUNT queries, ${best_min_time}-${best_max_time} ms"
echo ""
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "To use this DNS server, configure your network settings with:"
echo -e "  Primary DNS: ${YELLOW}${best_ip}${NC}"
echo ""
echo -e "Note: this benchmarks resolver latency from this machine. Validate again on the target network before changing production DNS."
echo ""
