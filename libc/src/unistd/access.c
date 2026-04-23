#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <f2c.h>

integer ipaccess_(char*p, integer* modp, ftnlen len) /* i -- interger
                                                       * p -- posix
                                                       */
{
    int mode = 0, res;
    char* s = malloc(sizeof(char) * ((size_t)len + 1));
    if (!s) return -1;

    strncpy(s, p, (size_t)len);
    s[len] = '\0';
    if (modp) mode = *modp;

    res = access(s, mode);
    free(s);

    return res;
}
