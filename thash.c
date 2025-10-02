#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>

#ifdef _WIN32
    #include <windows.h>
    #include <io.h>
    #define stat _stat
    #define fstat _fstat
#else
    #include <sys/stat.h>
    #include <unistd.h>
#endif

#define BUF_SIZE 8388608  // 8 MB buffer (optimal for both Windows/Linux)

// Fast hash computation with hardware acceleration
static inline void compute_hash(const unsigned char *data, size_t len, unsigned char *hash) {
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(ctx, EVP_sha256(), NULL);  // Auto uses HW SHA if available
    EVP_DigestUpdate(ctx, data, len);
    EVP_DigestFinal_ex(ctx, hash, NULL);
    EVP_MD_CTX_free(ctx);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }

    unsigned char hash[32];

#ifdef _WIN32
    // ============ WINDOWS OPTIMIZED PATH ============
    HANDLE hFile = CreateFileA(
        argv[1],
        GENERIC_READ,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_SEQUENTIAL_SCAN,  // Hint for sequential access
        NULL
    );

    if (hFile == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "Error opening file: %s\n", argv[1]);
        return 1;
    }

    LARGE_INTEGER fileSize;
    if (!GetFileSizeEx(hFile, &fileSize)) {
        fprintf(stderr, "Error getting file size\n");
        CloseHandle(hFile);
        return 1;
    }

    if (fileSize.QuadPart == 0) {
        fprintf(stderr, "Empty file\n");
        CloseHandle(hFile);
        return 1;
    }

    // Use memory mapping for large files (>10MB)
    if (fileSize.QuadPart > 10485760) {
        HANDLE hMapping = CreateFileMappingA(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
        if (hMapping) {
            void *mapped = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0);
            if (mapped) {
                compute_hash((unsigned char*)mapped, (size_t)fileSize.QuadPart, hash);
                UnmapViewOfFile(mapped);
                CloseHandle(hMapping);
                CloseHandle(hFile);
                goto print_result;
            }
            CloseHandle(hMapping);
        }
    }

    // Fallback: buffered reading with large buffer
    unsigned char *buffer = (unsigned char*)_aligned_malloc(BUF_SIZE, 4096);
    if (!buffer) {
        fprintf(stderr, "Memory allocation failed\n");
        CloseHandle(hFile);
        return 1;
    }

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(ctx, EVP_sha256(), NULL);

    DWORD bytesRead;
    while (ReadFile(hFile, buffer, BUF_SIZE, &bytesRead, NULL) && bytesRead > 0) {
        EVP_DigestUpdate(ctx, buffer, bytesRead);
    }

    EVP_DigestFinal_ex(ctx, hash, NULL);
    EVP_MD_CTX_free(ctx);
    _aligned_free(buffer);
    CloseHandle(hFile);

#else
    // ============ LINUX OPTIMIZED PATH ============
    #include <sys/mman.h>
    #include <fcntl.h>

    int fd = open(argv[1], O_RDONLY);
    if (fd == -1) {
        perror("Error opening file");
        return 1;
    }

    struct stat st;
    if (fstat(fd, &st) == -1) {
        perror("Error getting file size");
        close(fd);
        return 1;
    }

    if (st.st_size == 0) {
        fprintf(stderr, "Empty file\n");
        close(fd);
        return 1;
    }

    // Use mmap for large files
    if (st.st_size > 10485760) {
        void *mapped = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (mapped != MAP_FAILED) {
            madvise(mapped, st.st_size, MADV_SEQUENTIAL);
            compute_hash(mapped, st.st_size, hash);
            munmap(mapped, st.st_size);
            close(fd);
            goto print_result;
        }
    }

    // Fallback: buffered reading
    unsigned char *buffer;
    if (posix_memalign((void**)&buffer, 4096, BUF_SIZE) != 0) {
        fprintf(stderr, "Memory allocation failed\n");
        close(fd);
        return 1;
    }

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(ctx, EVP_sha256(), NULL);

    ssize_t bytesRead;
    while ((bytesRead = read(fd, buffer, BUF_SIZE)) > 0) {
        EVP_DigestUpdate(ctx, buffer, bytesRead);
    }

    EVP_DigestFinal_ex(ctx, hash, NULL);
    EVP_MD_CTX_free(ctx);
    free(buffer);
    close(fd);
#endif

print_result:
    // Optimized hex output
    static const char hex[] = "0123456789abcdef";
    printf("SHA256(%s) = ", argv[1]);
    for (int i = 0; i < 32; i++) {
        putchar(hex[hash[i] >> 4]);
        putchar(hex[hash[i] & 0xf]);
    }
    putchar('\n');

    return 0;
}