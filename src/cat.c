#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define PROGRAM_NAME "cat"

#define BUF_SIZE 4096

int cat(int fd, const char *filename) {
  char buf[BUF_SIZE];
  ssize_t bytes_read;
  ssize_t bytes_written;

  while ((bytes_read = read(fd, buf, BUF_SIZE)) > 0) {
    size_t total_written = 0;

    while (total_written < (size_t)bytes_read) {
      bytes_written =
          write(STDOUT_FILENO, buf + total_written, bytes_read - total_written);

      if (bytes_written < 0) {
        perror("cat: write error");
        return -1;
      }
      total_written += bytes_written;
    }
  }

  if (bytes_read < 0) {
    fprintf(stderr, "cat: ");
    perror(filename);
    return -1;
  }

  return 0;
}

int main(int argc, char *argv[]) {
  int status = 0;

  if (argc == 1)
    if (cat(STDIN_FILENO, "stdin") != 0)
      status = 1;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-u") == 0)
      continue;
    if (strcmp(argv[i], "-") == 0) {
      if (cat(STDIN_FILENO, "stdin") != 0)
        status = 1;
      continue;
    }

    int fd = open(argv[i], O_RDONLY);
    if (fd < 0) {
      fprintf(stderr, "cat: ");
      perror(argv[i]);
      status = 1;
      continue;
    }

    if (cat(fd, argv[i]) != 0)
      status = 1;
    close(fd);
  }
  return status;
}
