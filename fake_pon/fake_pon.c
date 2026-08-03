/*
 * fake_pon.c — LD_PRELOAD shim that emulates /dev/pon for ponmgr/omciMgr
 *
 * Intercepts open/openat("/dev/pon") and ioctl/read/write/close/mmap
 * on it, returning fake data so PON daemons start in LXC.
 *
 * Build:  aarch64-linux-gnu-gcc -shared -fPIC -o fake_pon.so fake_pon.c -ldl
 *         (or gcc -shared -fPIC -o fake_pon.so fake_pon.c -ldl on aarch64)
 * Use:    LD_PRELOAD=/usr/lib/fake_pon.so ponmgr gpon get info
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>
#include <sys/ioctl.h>
#include <sys/stat.h>

/* PON device major/minor from vendor init script */
#define PON_DEV_MAJOR 190
#define PON_DEV_MINOR   0

/* Fake fd for /dev/pon */
static int fake_pon_fd = 9000;
static int fake_pon_opened = 0;

/* ── ioctl command constants (from vendor kernel headers) ──────── */
/* XMCS PON driver ioctl magic — approximate from reverse engineering */
#define XMCS_IOCTL_SDI       0x1001  /* SDI (Serial Data Interface) */
#define XMCS_IOCTL_GET_STATUS 0x1002
#define XMCS_IOCTL_GET_OPTICAL 0x1003
#define XMCS_IOCTL_SET_CFG   0x1004

/* Fake PON status: "Up" = registered, FEC enabled */
static int fake_pon_status = 1;     /* 0=down, 1=up */
static int fake_fec_rx = 1;
static int fake_fec_tx = 1;
static int fake_sn_set = 0;

/* Fake optical values (in 0.001 dBm units, like /proc/tc3162) */
static int fake_tx_power = 2300;    /* +2.3 dBm */
static int fake_rx_power = -18500;  /* -18.5 dBm */
static int fake_temperature = 4500; /* 45.00 C */
static int fake_bias = 12000;       /* 12 mA */
static int fake_voltage = 3300;     /* 3.3V */

/* ── Intercept open() ─────────────────────────────────────────── */

typedef int (*orig_open_t)(const char *pathname, int flags, ...);

int open(const char *pathname, int flags, ...) {
    orig_open_t real_open = (orig_open_t)dlsym(RTLD_NEXT, "open");

    if (pathname && strcmp(pathname, "/dev/pon") == 0) {
        if (!fake_pon_opened) {
            fake_pon_opened = 1;
        }
        return fake_pon_fd;
    }

    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode_t mode = va_arg(args, mode_t);
        va_end(args);
        return real_open(pathname, flags, mode);
    }
    return real_open(pathname, flags);
}

/* ── Intercept openat() (vendor binaries use this on aarch64) ── */

typedef int (*orig_openat_t)(int dirfd, const char *pathname, int flags, ...);

int openat(int dirfd, const char *pathname, int flags, ...) {
    orig_openat_t real_openat = (orig_openat_t)dlsym(RTLD_NEXT, "openat");

    if (pathname && (strcmp(pathname, "/dev/pon") == 0 ||
                     strcmp(pathname, "/dev/pon0") == 0)) {
        if (!fake_pon_opened) {
            fake_pon_opened = 1;
        }
        return fake_pon_fd;
    }

    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode_t mode = va_arg(args, mode_t);
        va_end(args);
        return real_openat(dirfd, pathname, flags, mode);
    }
    return real_openat(dirfd, pathname, flags);
}

/* ── Intercept close() ────────────────────────────────────────── */

typedef int (*orig_close_t)(int fd);

int close(int fd) {
    orig_close_t real_close = (orig_close_t)dlsym(RTLD_NEXT, "close");
    if (fd == fake_pon_fd) {
        return 0;
    }
    return real_close(fd);
}

/* ── Intercept ioctl() ────────────────────────────────────────── */

typedef int (*orig_ioctl_t)(int fd, unsigned long request, ...);

int ioctl(int fd, unsigned long request, ...) {
    va_list args;
    va_start(args, request);
    void *argp = va_arg(args, void *);
    va_end(args);

    if (fd != fake_pon_fd)
        return 0;

    /* XMCS_IOCTL_SDI — the one that floods errors */
    if (request == XMCS_IOCTL_SDI) {
        /* Zero out the buffer to return "all zeros" status */
        if (argp) memset(argp, 0, 256);
        return 0;
    }

    /* All other ioctls — return success with zeroed buffer */
    if (argp) memset(argp, 0, 256);
    return 0;
}

/* ── Intercept ioctl64 (some binaries use this) ──────────────── */

int ioctl64(int fd, unsigned long request, ...) {
    va_list args;
    va_start(args, request);
    void *argp = va_arg(args, void *);
    va_end(args);

    if (fd != fake_pon_fd) {
        orig_ioctl_t real_ioctl = (orig_ioctl_t)dlsym(RTLD_NEXT, "ioctl");
        return real_ioctl(fd, request, argp);
    }

    if (argp) memset(argp, 0, 256);
    return 0;
}

/* ── Intercept write() to /dev/pon ────────────────────────────── */

typedef ssize_t (*orig_write_t)(int fd, const void *buf, size_t count);

ssize_t write(int fd, const void *buf, size_t count) {
    if (fd == fake_pon_fd) {
        return count;
    }
    orig_write_t real_write = (orig_write_t)dlsym(RTLD_NEXT, "write");
    return real_write(fd, buf, count);
}

/* ── Intercept read() from /dev/pon ───────────────────────────── */

typedef ssize_t (*orig_read_t)(int fd, void *buf, size_t count);

ssize_t read(int fd, void *buf, size_t count) {
    if (fd == fake_pon_fd) {
        /* Return empty data */
        return 0;
    }
    orig_read_t real_read = (orig_read_t)dlsym(RTLD_NEXT, "read");
    return real_read(fd, buf, count);
}

/* ── Intercept mmap (some drivers use this) ───────────────────── */

typedef void* (*orig_mmap_t)(void *addr, size_t length, int prot,
                             int flags, int fd, off_t offset);

void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
    if (fd == fake_pon_fd) {
        /* Return anonymous memory */
        void *p = malloc(length);
        if (p) memset(p, 0, length);
        return p;
    }
    orig_mmap_t real_mmap = (orig_mmap_t)dlsym(RTLD_NEXT, "mmap");
    return real_mmap(addr, length, prot, flags, fd, offset);
}
