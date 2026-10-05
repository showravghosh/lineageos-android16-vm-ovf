/* Static shim for LineageOS bootmgr prebuilt tools on a host whose glibc
 * differs from the bundled one.
 *
 * The build runs grub-mkrescue under LineageOS's bundled glibc 2.41 with
 * LD_LIBRARY_PATH=prebuilts/bootmgr/lib64. Children inherit that, so any tool
 * grub-mkrescue spawns (xorriso, mformat, mcopy, mmd...) is started by the
 * system loader (Ubuntu 26.04 = glibc 2.43) but forced to load the bundled
 * libc 2.41. glibc's loader and libc must come from the same build, so the
 * child segfaults. grub reports that as "not found" / "invocation failed".
 *
 * A shell wrapper cannot fix this - the shell segfaults the same way. Built
 * -static so the dynamic loader is never involved.
 *
 * Dispatches on argv[0]: installed as "mformat" it execs /usr/bin/mformat.
 */
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    static char path[512] = "/usr/bin/";
    const char *base, *slash;
    (void)argc;

    base = argv[0] ? argv[0] : "";
    slash = strrchr(base, '/');
    if (slash)
        base = slash + 1;

    strncat(path, base, sizeof(path) - strlen(path) - 1);

    unsetenv("LD_LIBRARY_PATH");
    argv[0] = path;
    execv(path, argv);
    _exit(127);
}
