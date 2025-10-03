# THash - Ultra-Fast SHA256 File Hasher

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue.svg)]()
[![Performance](https://img.shields.io/badge/performance-1.7x%20faster-green.svg)]()

A high-performance, cross-platform SHA256 file hashing tool optimized for speed and efficiency. Up to **1.7x faster** than standard system tools.

## ✨ Features

- 🚀 **Hardware Acceleration** - Automatically uses Intel SHA-NI or ARM Crypto extensions
- ⚡ **Memory Mapping** - Zero-copy operations for large files
- 🔄 **Cross-Platform** - Works on Windows and Linux with optimized code paths
- 💾 **Smart Buffering** - Adaptive algorithm based on file size
- 🎯 **100% Accurate** - Verified against standard SHA256 implementations

## 📊 Performance

Tested on Windows with 20-core CPU and SHA-NI support:

| File Size | System Tool | THash | Speedup |
|-----------|-------------|-------|---------|
| 1 MB | 15 ms | 9 ms | **1.67x** |
| 10 MB | 89 ms | 52 ms | **1.71x** |
| 50 MB | 238 ms | 141 ms | **1.69x** |

## 🛠️ Installation

### Prerequisites

#### Windows (MSYS2/MinGW)
```bash
pacman -S mingw-w64-ucrt-x86_64-gcc
pacman -S mingw-w64-ucrt-x86_64-openssl
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install build-essential libssl-dev
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install gcc openssl-devel
```

### Build

```bash
# Clone the repository
git clone https://github.com/imNero1/thash.git
cd thash

# Compile with optimizations
gcc -O3 -march=native thash.c -lssl -lcrypto -o thash
```

On Windows, use `.exe` extension:
```bash
gcc -O3 -march=native thash.c -lssl -lcrypto -o thash.exe
```

## 🚀 Usage

```bash
# Basic usage
./thash <file>

# Example
./thash document.pdf
```

**Output:**
```
SHA256(document.pdf) = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## 🧪 Testing

Run the included test suite to verify correctness and performance:

```bash
# Make test script executable
chmod +x test.sh

# Run tests
./test.sh
```

The test suite will:
- ✅ Verify hash correctness against system tools
- ⚡ Benchmark performance
- 🖥️ Check hardware acceleration support
- 📊 Provide a detailed report with grade

## 🏗️ How It Works

### Optimization Techniques

1. **Hardware Acceleration**: Uses OpenSSL's EVP API which automatically detects and uses CPU SHA extensions (Intel SHA-NI, ARM Crypto)

2. **Memory Mapping**: For files larger than 10 MB, uses memory-mapped I/O (mmap on Linux, CreateFileMapping on Windows) for zero-copy operations

3. **Smart Buffering**: Falls back to optimized buffered reading with 8 MB aligned buffers for smaller files or when memory mapping fails

4. **Platform-Specific APIs**: Uses native OS APIs (Windows API on Windows, POSIX on Linux) for maximum performance.

### Code Structure

```
thash.c
├── Windows Path (#ifdef _WIN32)
│   ├── CreateFileMapping/MapViewOfFile (memory mapping)
│   ├── ReadFile (buffered reading)
│   └── _aligned_malloc (aligned buffers)
│
└── Linux Path (#else)
    ├── mmap (memory mapping)
    ├── read (buffered reading)
    └── posix_memalign (aligned buffers)
```

## 🔍 Technical Details

- **Algorithm**: SHA-256 (256-bit Secure Hash Algorithm)
- **Buffer Size**: 8 MB for optimal performance
- **Memory Mapping Threshold**: Files > 10 MB
- **Memory Alignment**: 4096 bytes (page-aligned)
- **OpenSSL Version**: Compatible with OpenSSL 1.1.0+

## 📈 Benchmarks

### System Specifications
- **CPU**: Intel Core (20 cores, SHA-NI enabled)
- **OS**: Windows 11 (UCRT64)
- **Compiler**: GCC with -O3 -march=native
- **Test**: 50 MB random binary file

### Results
- **Correctness**: 100% (all hashes verified)
- **Performance**: 1.69x faster than sha256sum
- **Hardware Acceleration**: Active ✅

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenSSL for the cryptographic library
- Community feedback and testing

---

⭐ If you find this project useful, please consider giving it a star on GitHub!
