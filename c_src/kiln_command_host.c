#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
#define _DARWIN_C_SOURCE 1
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#if defined(__APPLE__)
#include <AvailabilityVersions.h>
#endif

static long elapsed_ms(struct timespec start, struct timespec end) {
  return (end.tv_sec - start.tv_sec) * 1000L +
         (end.tv_nsec - start.tv_nsec) / 1000000L;
}

static int write_result(const char *path, int exit_code, int signal_number,
                        bool timed_out, long duration_ms) {
  FILE *file = fopen(path, "w");
  if (file == NULL) return -1;
  int result = fprintf(file,
    "{\"exit_code\":%d,\"signal\":%d,\"timed_out\":%s,\"duration_ms\":%ld}\n",
    exit_code, signal_number, timed_out ? "true" : "false", duration_ms);
  int close_result = fclose(file);
  return result < 0 || close_result != 0 ? -1 : 0;
}

int main(int argc, char **argv) {
  const char *cwd = NULL, *stdout_path = NULL, *stderr_path = NULL;
  const char *result_path = NULL, *path_value = NULL, *home_value = NULL;
  const char *tmpdir_value = NULL;
  long timeout_ms = 0;
  int command_index = -1;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--") == 0) { command_index = i + 1; break; }
    if (i + 1 >= argc) return 64;
    if (strcmp(argv[i], "--cwd") == 0) cwd = argv[++i];
    else if (strcmp(argv[i], "--timeout-ms") == 0) timeout_ms = strtol(argv[++i], NULL, 10);
    else if (strcmp(argv[i], "--stdout") == 0) stdout_path = argv[++i];
    else if (strcmp(argv[i], "--stderr") == 0) stderr_path = argv[++i];
    else if (strcmp(argv[i], "--result") == 0) result_path = argv[++i];
    else if (strcmp(argv[i], "--path") == 0) path_value = argv[++i];
    else if (strcmp(argv[i], "--home") == 0) home_value = argv[++i];
    else if (strcmp(argv[i], "--tmpdir") == 0) tmpdir_value = argv[++i];
    else return 64;
  }

  if (cwd == NULL || stdout_path == NULL || stderr_path == NULL ||
      result_path == NULL || path_value == NULL || home_value == NULL ||
      tmpdir_value == NULL || timeout_ms <= 0 || command_index < 0 ||
      command_index >= argc || argv[command_index][0] != '/') return 64;

  posix_spawn_file_actions_t actions;
  posix_spawnattr_t attributes;
  if (posix_spawn_file_actions_init(&actions) != 0) return 70;
  if (posix_spawnattr_init(&attributes) != 0) return 70;
#if defined(__APPLE__)
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_26_0
  if (posix_spawn_file_actions_addchdir(&actions, cwd) != 0) return 70;
#else
  if (posix_spawn_file_actions_addchdir_np(&actions, cwd) != 0) return 70;
#endif
#else
  if (chdir(cwd) != 0) return 70;
#endif
  if (posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, stdout_path,
      O_WRONLY | O_CREAT | O_TRUNC, 0600) != 0) return 70;
  if (posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, stderr_path,
      O_WRONLY | O_CREAT | O_TRUNC, 0600) != 0) return 70;
  if (posix_spawnattr_setflags(&attributes, POSIX_SPAWN_SETPGROUP) != 0) return 70;
  if (posix_spawnattr_setpgroup(&attributes, 0) != 0) return 70;

  size_t path_size = strlen(path_value) + 6;
  size_t home_size = strlen(home_value) + 6;
  size_t tmpdir_size = strlen(tmpdir_value) + 8;
  char *path_env = malloc(path_size);
  char *home_env = malloc(home_size);
  char *tmpdir_env = malloc(tmpdir_size);
  if (path_env == NULL || home_env == NULL || tmpdir_env == NULL) return 70;
  snprintf(path_env, path_size, "PATH=%s", path_value);
  snprintf(home_env, home_size, "HOME=%s", home_value);
  snprintf(tmpdir_env, tmpdir_size, "TMPDIR=%s", tmpdir_value);
  char *child_env[] = {path_env, home_env, tmpdir_env, "LANG=C.UTF-8",
                       "LC_ALL=C.UTF-8", "MIX_ENV=test", "CI=1", NULL};

  pid_t child = 0;
  struct timespec started, current;
  clock_gettime(CLOCK_MONOTONIC, &started);
  int spawn_result = posix_spawn(&child, argv[command_index], &actions,
                                 &attributes, &argv[command_index], child_env);
  posix_spawn_file_actions_destroy(&actions);
  posix_spawnattr_destroy(&attributes);
  free(path_env);
  free(home_env);
  free(tmpdir_env);
  if (spawn_result != 0) {
    errno = spawn_result;
    perror("posix_spawn");
    return 69;
  }

  int status = 0;
  bool timed_out = false;
  while (waitpid(child, &status, WNOHANG) == 0) {
    clock_gettime(CLOCK_MONOTONIC, &current);
    if (elapsed_ms(started, current) >= timeout_ms) {
      timed_out = true;
      kill(-child, SIGTERM);
      struct timespec grace = {.tv_sec = 0, .tv_nsec = 250000000L};
      nanosleep(&grace, NULL);
      if (waitpid(child, &status, WNOHANG) == 0) kill(-child, SIGKILL);
      waitpid(child, &status, 0);
      break;
    }
    struct timespec interval = {.tv_sec = 0, .tv_nsec = 10000000L};
    nanosleep(&interval, NULL);
  }
  if (kill(-child, 0) == 0 || errno != ESRCH) kill(-child, SIGKILL);

  clock_gettime(CLOCK_MONOTONIC, &current);
  int exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
  int signal_number = WIFSIGNALED(status) ? WTERMSIG(status) : 0;
  if (write_result(result_path, exit_code, signal_number, timed_out,
                   elapsed_ms(started, current)) != 0) return 74;
  return 0;
}
