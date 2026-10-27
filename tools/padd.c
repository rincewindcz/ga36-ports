// padd FIFO : uinput clone of the GA36-MB Gamepad (same name, bus, keys and
// axes, so SDL gives it the same GUID and mapping), driven by lines written
// to FIFO (root):
//   tap CODE [MS]    press CODE for MS milliseconds (default 100)
//   down CODE        press CODE
//   up CODE          release CODE
//   abs AXIS VALUE   set ABS_X, ABS_Y, ABS_RX or ABS_RY (0, 1, 3, 4) to VALUE
//   sleep MS
// Codes: 304 B, 305 A, 307 X, 308 Y, 310 L1, 311 R1, 312 L2, 313 R2,
// 314 Select, 315 Start, 316 Mode, 317 L3, 318 R3, 544-547 d-pad up, down,
// left, right (SDL buttons b0 to b16 in this order).
#include <fcntl.h>
#include <linux/uinput.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const int keys[] = { 304, 305, 307, 308, 310, 311, 312, 313, 314, 315, 316, 317, 318, 544, 545, 546, 547 };
static const int axes[] = { ABS_X, ABS_Y, ABS_RX, ABS_RY };

static void emit(int fd, int type, int code, int value)
{
    struct input_event ev = { .type = type, .code = code, .value = value };
    if (write(fd, &ev, sizeof(ev)) != sizeof(ev))
        perror("write");
}

static void report(int fd, int type, int code, int value)
{
    emit(fd, type, code, value);
    emit(fd, EV_SYN, SYN_REPORT, 0);
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "usage: %s FIFO\n", argv[0]);
        return 1;
    }
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("/dev/uinput");
        return 1;
    }
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++)
        ioctl(fd, UI_SET_KEYBIT, keys[i]);
    for (size_t i = 0; i < sizeof(axes) / sizeof(axes[0]); i++) {
        struct uinput_abs_setup abs = { .code = axes[i], .absinfo = { .minimum = -32767, .maximum = 32767 } };
        ioctl(fd, UI_SET_ABSBIT, axes[i]);
        ioctl(fd, UI_ABS_SETUP, &abs);
    }
    struct uinput_setup setup = { .id = { .bustype = 0x19 } };
    strcpy(setup.name, "GA36-MB Gamepad");
    if (ioctl(fd, UI_DEV_SETUP, &setup) < 0 || ioctl(fd, UI_DEV_CREATE) < 0) {
        perror("uinput");
        return 1;
    }

    // O_RDWR keeps the FIFO open between writers
    FILE *in = fopen(argv[1], "r+");
    if (in == NULL) {
        perror(argv[1]);
        return 1;
    }
    char line[128], cmd[16];
    int a, b;
    while (fgets(line, sizeof(line), in) != NULL) {
        int n = sscanf(line, "%15s %d %d", cmd, &a, &b);
        if (n >= 2 && strcmp(cmd, "tap") == 0) {
            report(fd, EV_KEY, a, 1);
            usleep((n == 3 ? b : 100) * 1000);
            report(fd, EV_KEY, a, 0);
        } else if (n == 2 && strcmp(cmd, "down") == 0) {
            report(fd, EV_KEY, a, 1);
        } else if (n == 2 && strcmp(cmd, "up") == 0) {
            report(fd, EV_KEY, a, 0);
        } else if (n == 3 && strcmp(cmd, "abs") == 0) {
            report(fd, EV_ABS, a, b);
        } else if (n == 2 && strcmp(cmd, "sleep") == 0) {
            usleep(a * 1000);
        } else {
            fprintf(stderr, "padd: bad command: %s", line);
        }
    }

    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
