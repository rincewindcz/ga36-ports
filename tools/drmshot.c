// Writes the framebuffer of the first active DRM plane as a binary PPM to stdout.
// The PPM has no alpha; for ARGB8888 the number of non-opaque pixels, which the
// display mixer blends with black, is reported on stderr.
// Needs root (GETFB2 only returns buffer handles to CAP_SYS_ADMIN); XRGB8888/ARGB8888 only.
//
// Usage: drmshot [/dev/dri/cardN] > shot.ppm
#include <drm/drm.h>
#include <drm/drm_fourcc.h>
#include <drm/drm_mode.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

static void die(const char *what)
{
    perror(what);
    exit(1);
}

int main(int argc, char **argv)
{
    int fd = open(argc > 1 ? argv[1] : "/dev/dri/card1", O_RDWR);
    if (fd < 0) die("open");
    ioctl(fd, DRM_IOCTL_SET_CLIENT_CAP, &(struct drm_set_client_cap){DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1});

    uint32_t planes[32];
    struct drm_mode_get_plane_res res = {.plane_id_ptr = (uintptr_t)planes, .count_planes = 32};
    if (ioctl(fd, DRM_IOCTL_MODE_GETPLANERESOURCES, &res)) die("GETPLANERESOURCES");

    struct drm_mode_fb_cmd2 fb = {0};
    for (uint32_t i = 0; i < res.count_planes && !fb.fb_id; i++) {
        struct drm_mode_get_plane plane = {.plane_id = planes[i]};
        if (ioctl(fd, DRM_IOCTL_MODE_GETPLANE, &plane)) die("GETPLANE");
        fb.fb_id = plane.fb_id;
    }
    if (!fb.fb_id) {
        fprintf(stderr, "drmshot: no active plane\n");
        return 1;
    }
    if (ioctl(fd, DRM_IOCTL_MODE_GETFB2, &fb)) die("GETFB2");
    if (fb.pixel_format != DRM_FORMAT_XRGB8888 && fb.pixel_format != DRM_FORMAT_ARGB8888) {
        fprintf(stderr, "drmshot: unsupported format %.4s\n", (char *)&fb.pixel_format);
        return 1;
    }

    struct drm_mode_map_dumb map = {.handle = fb.handles[0]};
    if (ioctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &map)) die("MAP_DUMB");
    size_t size = (size_t)fb.pitches[0] * fb.height + fb.offsets[0];
    const uint8_t *px = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, map.offset);
    if (px == MAP_FAILED) die("mmap");

    unsigned long translucent = 0;
    printf("P6\n%u %u\n255\n", fb.width, fb.height);
    for (uint32_t y = 0; y < fb.height; y++) {
        const uint8_t *row = px + fb.offsets[0] + (size_t)y * fb.pitches[0];
        for (uint32_t x = 0; x < fb.width; x++) {
            const uint8_t *p = row + x * 4;
            putchar(p[2]);
            putchar(p[1]);
            putchar(p[0]);
            translucent += p[3] != 0xff;
        }
    }
    if (fb.pixel_format == DRM_FORMAT_ARGB8888 && translucent)
        fprintf(stderr, "drmshot: %lu of %u pixels not opaque\n", translucent, fb.width * fb.height);
    return 0;
}
