#include "../../include/coreutils.h"
#include <errno.h>

void p_error(const char *utility, const char *msg) {
  if (errno != 0) {
    fprintf(stderr, "%s: %s: %s\n", utility, msg, strerror(errno));
  } else {
    fprintf(stderr, "%s: %s\n", utility, msg);
  }
}

void *xmalloc(size_t size) {
  void *ptr = malloc(size);
  if (!ptr && size != 0) {
    p_error("coreutils", "out of memory");
    exit(EXIT_FAILURE);
  }
  return ptr;
}

char *xstrdup(const char *s) {
  char *ptr = strdup(s);
  if (!ptr && s != NULL) {
    p_error("coreutils", "out of memory");
    exit(EXIT_FAILURE);
  }
  return ptr;
}

ssize_t safe_read(int fd, void *buf, size_t count) {
  ssize_t result;
  do {
    result = read(fd, buf, count);
  } while (result < 0 && errno == EINTR);
  return result;
}

ssize_t safe_write(int fd, const void *buf, size_t count) {
  size_t total_written = 0;
  const char *p = buf;
  while (total_written < count) {
    ssize_t written = write(fd, p + total_written, count - total_written);
    if (written < 0) {
      if (errno == EINTR)
        continue;
      return -1;
    }
    total_written += written;
  }
  return total_written;
}

const char *get_posix_file_type(mode_t mode) {
  if (S_ISREG(mode))
    return "regular file";
  if (S_ISDIR(mode))
    return "directory";
  if (S_ISLNK(mode))
    return "symbolic link";
  if (S_ISFIFO(mode))
    return "fifo/pipe";
  if (S_ISSOCK(mode))
    return "socket";
  if (S_ISCHR(mode))
    return "character device";
  if (S_ISBLK(mode))
    return "block device";
  return "unknown";
}

mode_t parse_posix_mode(const char *mode_str, mode_t initial_mode) {
  if (mode_str == NULL || *mode_str == '\0') {
    return (mode_t)-1;
  }

  char *endptr;
  /* 1. Check if it's a standard octal number string first */
  long val = strtol(mode_str, &endptr, 8);
  if (*endptr == '\0') {
    if (val < 0 || val > 07777)
      return (mode_t)-1;
    return (mode_t)val;
  }

  mode_t mode = initial_mode;
  const char *p = mode_str;

  /* 2. Standard POSIX Bitmask Mapping Definitions */
  const mode_t USER_BITS = S_IRWXU;   // 0700
  const mode_t GROUP_BITS = S_IRWXG;  // 0070
  const mode_t OTHERS_BITS = S_IRWXO; // 0007
  const mode_t ALL_BITS = S_IRWXU | S_IRWXG | S_IRWXO;

  /* Loop through comma-separated clauses */
  while (*p != '\0') {
    mode_t who = 0;
    mode_t perm = 0;
    char op = '\0';

    /* Parse 'who' segment */
    bool who_specified = false;
    while (*p && strchr("ugoa", *p) != NULL) {
      who_specified = true;
      switch (*p) {
      case 'u':
        who |= USER_BITS;
        break;
      case 'g':
        who |= GROUP_BITS;
        break;
      case 'o':
        who |= OTHERS_BITS;
        break;
      case 'a':
        who |= ALL_BITS;
        break;
      }
      p++;
    }
    /* POSIX rule: If no 'who' is specified, the default matches 'a' (all) */
    if (!who_specified) {
      mode_t mask = umask(0);
      umask(mask);
      who = ALL_BITS & ~mask;
    }

    /* Parse operator */
    if (*p && strchr("-+=", *p) != NULL) {
      op = *p;
      p++;
    } else {
      return (mode_t)-1; /* Syntax Error */
    }

    /* Parse 'perm' segment */
    while (*p && strchr("rwx", *p) != NULL) {
      switch (*p) {
      case 'r':
        perm |= (S_IRUSR | S_IRGRP | S_IROTH);
        break;
      case 'w':
        perm |= (S_IWUSR | S_IWGRP | S_IWOTH);
        break;
      case 'x':
        perm |= (S_IXUSR | S_IXGRP | S_IXOTH);
        break;
      }
      p++;
    }

    /* 3. Apply the operator using bitwise masks matching real file flags */
    switch (op) {
    case '+':
      mode |= (perm & who);
      break;
    case '-':
      mode &= ~(perm & who);
      break;
    case '=':
      mode &= ~who;         /* Clear target classes */
      mode |= (perm & who); /* Apply isolated bits */
      break;
    }

    /* Move past comma boundary */
    if (*p == ',') {
      p++;
      if (*p == '\0')
        return (mode_t)-1; /* Trailing comma error */
    } else if (*p != '\0') {
      return (mode_t)-1; /* Invalid garbage character encountered */
    }
  }

  return mode;
}
