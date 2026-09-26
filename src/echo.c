#include <stdio.h>
#include <unistd.h>

#define PROGRAM_NAME "echo"

int main(int argc, char *argv[]) {
  for (int i = 1; i < argc; i++) {
    if (i > 1) {
      putchar(' ');
    }

    fputs(argv[i], stdout);
  }

  putchar('\n');

  return 0;
}
