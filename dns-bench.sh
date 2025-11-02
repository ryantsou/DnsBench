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
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test domain for DNS lookups
TEST_DOMAIN="google.com"

# Number of pings per DNS server
PING_COUNT=5

################################################################################
# Function: check_dependencies
# Description: Verifies that required commands are available
################################################################################
check_dependencies() {
    local missing_deps=()
    
    for cmd in dig ping bc; do
        if ! command -v $cmd &> /dev/null; then
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
    
    for i in $(seq 1 $PING_COUNT); do
        # Perform DNS lookup and measure time
        local query_time=$(dig @${dns_ip} ${TEST_DOMAIN} +timeout=2 +tries=1 | \
            grep "Query time:" | \
            awk '{print $4}')
        
        if [ -n "$query_time" ] && [ "$query_time" != "0" ]; then
            total_time=$(echo "$total_time + $query_time" | bc)
            ((successful_queries++))
        fi
    done
    
    if [ $successful_queries -eq 0 ]; then
        echo "timeout"
    else
        # Calculate average
        local avg_time=$(echo "scale=2; $total_time / $successful_queries" | bc)
        echo "$avg_time"
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

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   DNS Server Benchmark Tool${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check dependencies
check_dependencies

echo -e "Testing domain: ${YELLOW}${TEST_DOMAIN}${NC}"
echo -e "Queries per server: ${YELLOW}${PING_COUNT}${NC}"
echo ""
echo -e "${BLUE}Benchmarking DNS servers...${NC}"
echo ""

# Store results
declare -A results
declare -a valid_servers

# Test each DNS server
for server_info in "${DNS_SERVERS[@]}"; do
    IFS='|' read -r name ip <<< "$server_info"
    
    echo -n "Testing $name ($ip)... "
    
    avg_time=$(test_dns_server "$ip")
    results["$name|$ip"]="$avg_time"
    
    # Display result
    formatted_time=$(format_time "$avg_time")
    echo -e "$formatted_time"
    
    # Store valid servers for ranking
    if [ "$avg_time" != "timeout" ]; then
        valid_servers+=("$name|$ip|$avg_time")
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

# Sort servers by response time
IFS=$'\n' sorted_servers=($(sort -t'|' -k3 -n <<< "${valid_servers[*]}"))
unset IFS

echo -e "${YELLOW}Ranked DNS Servers (fastest to slowest):${NC}"
echo ""

rank=1
for server_data in "${sorted_servers[@]}"; do
    IFS='|' read -r name ip time <<< "$server_data"
    echo -e "${rank}. $name ($ip): ${GREEN}${time} ms${NC}"
    ((rank++))
done

echo ""
echo -e "${BLUE}=====================================${NC}"

# Recommend the fastest server
IFS='|' read -r best_name best_ip best_time <<< "${sorted_servers[0]}"
echo -e "${GREEN}✓ Recommended DNS Server:${NC}"
echo -e "  ${YELLOW}${best_name}${NC} (${best_ip})"
echo -e "  Average response time: ${GREEN}${best_time} ms${NC}"
echo ""
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "To use this DNS server, configure your network settings with:"
echo -e "  Primary DNS: ${YELLOW}${best_ip}${NC}"
echo ""
