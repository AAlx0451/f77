#include <unistd.h>
#include <f2c.h>

void ipexit_(integer* statusptr) /* i -- void (non-real)
                                  * p -- posix (not exit())
                                  */
{
    int status = 0;
    if (statusptr) status = *statusptr;
    _exit(status);
}
