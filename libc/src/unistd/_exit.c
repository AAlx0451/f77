#include <unistd.h>

void iexitvp__(int* statusptr)
{
    int status = 0;
    if (statusptr) status = *statusptr;
    _exit(status);
}
