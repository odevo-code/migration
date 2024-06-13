# Migrate bitbucket repos

This repository contains two scripts, `migrate.sh` and `get_bitbucket_repos.sh`, that are used to migrate repositories from Bitbucket to GitHub.

## Prerequisites

- Git, jq, gh cli, and bash must be installed on your system. Windows users can install these prerequisites by running the `prepare.ps1` script. After running the script, please restart your terminal window to ensure the changes take effect.
- A GitHub account with necessary permissions to create repositories.
- A Bitbucket account with necessary permissions to read repositories.
- A `.env` file with the following variables (instructions on how to create an `.env` file are in the installation instructions):
  ```env
  BITBUCKET_USERNAME=your_bitbucket_username
  BITBUCKET_APP_PASSWORD=your_bitbucket_app_password (this is not the same as your login password, you need to create one)
  BITBUCKET_ORG=your_bitbucket_organization (this is what also is called workspace)
  BITBUCKET_DEFAULT_BRANCH=what is the name of the default branch you use, default: main
  GITHUB_ORG=the name of your GitHub organisation
  GITHUB_DEFAULT_BRANCH=the branchname you would like to have in GitHub, default: main
  GITHUB_TEAM=the name of the team where the repos should be in GitHub (must already exist)
  ```

## Installation

1. Clone this repository:

2. Create a `.env` file in the root directory of the project. You can do this using the command line:

  ```shell script
  touch .env
  ```

3. Open the `.env` file in a text editor and fill in your credentials as shown in the Prerequisites section and save it.

4. Make the scripts executable (not needed for Windows users):

  ### For MacOS/Linux:
  ```shell script
  chmod +x migrate.sh get_bitbucket_repos.sh
  ```

## Migrate Script

The `migrate.sh` script is the main script that handles the migration of repositories. It performs the following steps:

1. Clones the repository from Bitbucket.
2. Creates a new repository on GitHub.
3. Updates the remote URL to point to the new GitHub repository.
4. Creates a new branch with the name of the default branch.
5. Merges the old default branch into the new default branch without committing or fast-forwarding.
6. Commits the changes with a message.
7. Pushes the default branch to GitHub.
8. Loops through all other branches from origin and pushes them all to GitHub.

### Usage

If a repository name is provided as an argument (only MacOS/Linux), the script will migrate only that repository. If no argument is provided, the script will run the `get_bitbucket_repos.sh` script to fetch all repositories from the Bitbucket organization and migrate them.

### For MacOS/Linux:
```shell script
time ./migrate.sh
```

or

```shell script
./migrate.sh [repository_name]
```

### For Windows:
```shell script
./migrate.bat
```

## Get Bitbucket Repos Script

The `get_bitbucket_repos.sh` script is a helper script that fetches all repositories from a Bitbucket organization. It is used by the `migrate.sh` script when no repository name is provided as an argument.

### Usage

This script does not take any arguments. It reads the Bitbucket username, app password, and organization from a `.env` file.

```shell script
./get_bitbucket_repos.sh
```

## Remove Repos Script
This script do not take any arguments.

### For MacOS/Linux:
```shell script
./remove_repos.sh
```

### For Windows:
```shell script
./remove_repos.bat
```

---
For more details on how to use these scripts, see the complete documentation in the source code.
