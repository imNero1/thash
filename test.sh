#!/bin/bash
# SHA256 Testing Script for Windows (MSYS2)
# Run this in MSYS2 terminal

echo "======================================================="
echo "    SHA256 Ultra-Fast Code Testing (Windows)"
echo "======================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

# Step 1: Compile
echo -e "${YELLOW}[STEP 1]${NC} Compiling the code..."
gcc -O3 -march=native thash.c -lssl -lcrypto -o sha256_test.exe 2>errors.txt

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ COMPILATION FAILED!${NC}"
    echo "Errors:"
    cat errors.txt
    echo ""
    echo "Common fixes:"
    echo "1. Install OpenSSL: pacman -S mingw-w64-x86_64-openssl"
    echo "2. Make sure you're in MSYS2 MinGW 64-bit terminal"
    exit 1
else
    echo -e "${GREEN}✓ Compilation successful!${NC}"
    rm -f errors.txt
fi
echo ""

# Step 2: Create test files
echo -e "${YELLOW}[STEP 2]${NC} Creating test files..."

# Small text file
echo "Hello World!" > test_small.txt
echo -e "${GREEN}✓${NC} Created test_small.txt"

# 1 MB file
dd if=/dev/urandom of=test_1mb.bin bs=1024 count=1024 2>/dev/null
echo -e "${GREEN}✓${NC} Created test_1mb.bin (1 MB)"

# 10 MB file
dd if=/dev/urandom of=test_10mb.bin bs=1024 count=10240 2>/dev/null
echo -e "${GREEN}✓${NC} Created test_10mb.bin (10 MB)"

# 50 MB file for performance test
dd if=/dev/urandom of=test_50mb.bin bs=1024 count=51200 2>/dev/null
echo -e "${GREEN}✓${NC} Created test_50mb.bin (50 MB)"

echo ""

# Step 3: Correctness Tests
echo "======================================================="
echo "    CORRECTNESS TESTS"
echo "======================================================="
echo ""

test_file() {
    local filename=$1
    local test_num=$2
    
    echo -e "${BLUE}[TEST $test_num]${NC} Testing $filename..."
    
    # Get hash from our program
    our_hash=$(./sha256_test.exe "$filename" | grep -oE '[0-9a-f]{64}')
    
    # Get hash from system (try certutil on Windows, sha256sum on MSYS2)
    if command -v sha256sum &> /dev/null; then
        system_hash=$(sha256sum "$filename" | awk '{print $1}')
    else
        # Fallback to certutil (native Windows)
        system_hash=$(certutil -hashfile "$filename" SHA256 2>/dev/null | grep -v "SHA256" | grep -v "CertUtil" | tr -d ' \r\n' | tr '[:upper:]' '[:lower:]')
    fi
    
    echo "  Our hash:    $our_hash"
    echo "  System hash: $system_hash"
    
    if [ "$our_hash" == "$system_hash" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

test_file "test_small.txt" 1
test_file "test_1mb.bin" 2
test_file "test_10mb.bin" 3

# Step 4: Performance Test
echo "======================================================="
echo "    PERFORMANCE TEST (50 MB file)"
echo "======================================================="
echo ""

echo -e "${BLUE}[PERF]${NC} Testing with system tool..."
start_time=$(date +%s%N)
if command -v sha256sum &> /dev/null; then
    sha256sum test_50mb.bin > /dev/null
else
    certutil -hashfile test_50mb.bin SHA256 > /dev/null
fi
end_time=$(date +%s%N)
system_time=$(( (end_time - start_time) / 1000000 ))

echo -e "${BLUE}[PERF]${NC} Testing with our optimized version..."
start_time=$(date +%s%N)
./sha256_test.exe test_50mb.bin > /dev/null
end_time=$(date +%s%N)
our_time=$(( (end_time - start_time) / 1000000 ))

echo ""
echo -e "${YELLOW}Performance Results:${NC}"
echo "  System tool:      ${system_time} ms"
echo "  Our version:      ${our_time} ms"

if [ $our_time -lt $system_time ]; then
    speedup=$(echo "scale=2; $system_time / $our_time" | bc)
    echo -e "  ${GREEN}✓ Our version is ${speedup}x FASTER!${NC}"
else
    slowdown=$(echo "scale=2; $our_time / $system_time" | bc)
    echo -e "  ${YELLOW}⚠ Our version is ${slowdown}x slower${NC}"
fi
echo ""

# Step 5: Hardware Check
echo "======================================================="
echo "    HARDWARE CAPABILITIES"
echo "======================================================="
echo ""

# Check CPU info (Windows doesn't have /proc/cpuinfo)
echo "CPU Cores: $(nproc)"

# Try to detect SHA extensions
if grep -qi "sha" /proc/cpuinfo 2>/dev/null; then
    echo -e "${GREEN}✓ Hardware SHA acceleration detected${NC}"
elif command -v wmic &> /dev/null; then
    echo "Checking CPU features with wmic..."
    wmic cpu get caption 2>/dev/null | head -2
else
    echo "CPU feature detection not available"
fi
echo ""

# Step 6: Final Results
echo "======================================================="
echo "    FINAL RESULTS"
echo "======================================================="
echo ""

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$(echo "scale=0; ($PASSED * 100) / $TOTAL" | bc)
else
    PERCENTAGE=0
fi

echo "Tests Passed: ${GREEN}$PASSED${NC} / $TOTAL"
echo "Tests Failed: ${RED}$FAILED${NC} / $TOTAL"
echo ""
echo -e "${BLUE}Correctness Score: ${GREEN}${PERCENTAGE}%${NC}"

if [ $FAILED -eq 0 ]; then
    if [ $our_time -lt $system_time ]; then
        echo -e "\n${GREEN}╔════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   OVERALL GRADE: A+ (PERFECT!)    ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
    else
        echo -e "\n${GREEN}Overall Grade: A (Excellent - All tests passed!)${NC}"
    fi
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "\n${YELLOW}Overall Grade: B (Good - Minor issues)${NC}"
else
    echo -e "\n${RED}Overall Grade: C (Needs work)${NC}"
fi
echo ""

# Step 7: Cleanup
echo -e "${YELLOW}[CLEANUP]${NC} Removing test files..."
rm -f test_*.txt test_*.bin sha256_test.exe errors.txt
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo "Testing finished!"