C STANDART FILE DESCRIPTORS
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

C CONSTANTS FOR ICACCESSI()
#define F_OK 0
#define X_OK 1
#define W_OK 2
#define R_OK 4

#define _EXIT(X) IPEXIT(X)
C void _exit(int)
#define ACCESS(S, J) IPACCESS(S, J)
C int access(char *, int)
