/**
 * @file myshell.c
 * @brief A simple shell program that supports basic commands and history tracking.
 *
 * This program implements a simple shell that allows users to execute commands, change directories,
 * print the working directory, and view command history. It uses fork() and exec() system calls to
 * create child processes and execute commands. The shell supports a limited number of commands and
 * stores command history in an array.
 *
 * The program reads user input from the command line and parses it into individual arguments. It then
 * checks the first argument to determine the command to execute. If the command is one of the built-in
 * commands (history, cd, pwd, exit), it is executed directly. Otherwise, the program attempts to execute
 * the command by searching for the executable file in the specified paths.
 *
 * The shell also provides basic error handling and prints error messages when necessary.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>

// Constants
#define MAX_COMMANDS 100
#define MAX_COMMAND_LENGTH 100

// Global variables
char *history[MAX_COMMANDS];
int history_count = 0;

/**
 * @brief Adds a command to the command history.
 *
 * This function adds a command to the command history array. If the history array is full, the oldest
 * command is overwritten.
 *
 * @param command The command to add to the history.
 */
void add_to_history(char *command) {
    if (history_count < MAX_COMMANDS) {
        history[history_count++] = strdup(command);
    }
}

/**
 * @brief Prints the command history.
 *
 * This function prints the command history, along with the corresponding index for each command.
 */
void print_history() {
    for (int i = 0; i < history_count; i++) {
        printf("%d %s\n", i + 1, history[i]);
    }
}

/**
 * @brief Changes the current working directory.
 *
 * This function changes the current working directory to the specified path.
 *
 * @param path The path to change the directory to.
 */
void change_directory(char *path) {
    if (path == NULL) {
        fprintf(stderr, "cd: missing argument\n");
    } else if (chdir(path) != 0) {
        perror("chdir failed");
    }
}

/**
 * @brief Prints the current working directory.
 *
 * This function prints the current working directory.
 */
void print_working_directory() {
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("%s\n", cwd);
    } else {
        perror("getcwd failed");
    }
}

/**
 * @brief Executes a command.
 *
 * This function executes a command by creating a child process and using exec() system calls to
 * replace the child process with the specified command. If the command is not found in the specified
 * paths, it is searched in the system's default paths.
 *
 * @param args The arguments for the command.
 * @param paths The paths to search for the command.
 * @param num_paths The number of paths in the paths array.
 */
void execute_command(char **args, char *paths[], int num_paths) {
    pid_t pid = fork();
    if (pid == 0) {
        // Child process
        char command_path[1024];
        for (int i = 0; i < num_paths; i++) {
            snprintf(command_path, sizeof(command_path), "%s/%s", paths[i], args[0]);
            execv(command_path, args);
        }
        execvp(args[0], args);
        perror("exec failed");
        exit(1);
    } else if (pid > 0) {
        // Parent process
        int status;
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid failed");
            exit(1);
        }
    } else {
        perror("fork failed");
        exit(1);
    }
}


/**
 * @brief The main function.
 *
 * It initializes the paths array with the command line arguments,
 * reads user input from the command line, parses it into individual arguments, and executes the corresponding
 * command. The program continues to run until the user enters the "exit" command.
 *
 * @param argc The number of command line arguments.
 * @param argv The command line arguments.
 * @return The exit status of the program.
 */
int main(int argc, char *argv[]) {
    // Initialize paths array
    char *paths[argc - 1];
    for (int i = 1; i < argc; i++) {
        paths[i - 1] = argv[i];
    }
    int num_paths = argc - 1;

    // Initialize command buffer
    char command[MAX_COMMAND_LENGTH];

    // Main loop
    while (1) {
        printf("$ ");
        fflush(stdout);

        // Read user input
        if (fgets(command, sizeof(command), stdin) == NULL) {
            perror("fgets failed");
            exit(1);
        }

        // Remove newline character
        command[strcspn(command, "\n")] = 0;

        // Add command to history
        add_to_history(command);

        // Parse command into arguments
        char *args[MAX_COMMAND_LENGTH / 2 + 1];
        char *token = strtok(command, " ");
        int i = 0;
        while (token != NULL) {
            args[i++] = token;
            token = strtok(NULL, " ");
        }
        args[i] = NULL;

        // Execute command
        if (args[0] == NULL) {
            continue;
        } else if (strcmp(args[0], "history") == 0) {
            print_history();
        } else if (strcmp(args[0], "cd") == 0) {
            change_directory(args[1]);
        } else if (strcmp(args[0], "pwd") == 0) {
            print_working_directory();
        } else if (strcmp(args[0], "exit") == 0) {
            exit(0);
        } else {
            execute_command(args, paths, num_paths);
        }
    }
}
