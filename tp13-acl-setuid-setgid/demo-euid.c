#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("UID réel : %ld\n", (long)getuid());
    printf("UID effectif : %ld\n", (long)geteuid());
    return 0;
}

