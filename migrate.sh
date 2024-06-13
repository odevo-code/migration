#!/bin/bash

# Check if the user is logged in to GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
    echo "You are not logged in to GitHub CLI. Please log in using 'gh auth login' and try again."
    exit 1
fi

# Load environment variables from .env file
if [ -f .env ]; then
    # shellcheck disable=SC1091
    source .env
else
    echo "ERROR: .env file not found."
    exit 1
fi

# Check if required variables are set
required_vars=(BITBUCKET_USERNAME BITBUCKET_ORG GITHUB_ORG GITHUB_TEAM)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: $var is missing in the .env file."
        exit 1
    fi
done

BITBUCKET_DEFAULT_BRANCH="${BITBUCKET_DEFAULT_BRANCH:-main}"
GITHUB_DEFAULT_BRANCH="${GITHUB_DEFAULT_BRANCH:-main}"

GREEN=$(tput setaf 2)
NO_COLOR=$(tput sgr0)

# If an argument is given, use it as the repo to migrate
# Otherwise, run another script to fetch all repos from the Bitbucket organization
if [ $# -eq 1 ]; then
    repos_to_migrate=("$1")
else
    # Run another script to fetch all repos from the Bitbucket organization
    echo -e "${GREEN}Fetching all repos from Bitbucket...${NO_COLOR}"
    read -ra repos_to_migrate <<<"$(./get_bitbucket_repos.sh)" # Run the script to get all Bitbucket repos
fi

git config --global push.autosetupremote true

# Create the 'repos' directory if it doesn't exist
mkdir -p repos
# Change to the 'repos' directory
cd repos || {
    echo "Failed to change to directory: repos"
    exit 1
}

migrate_repo() {
    local repo="$1"
    local full_repo_path="$BITBUCKET_ORG/$repo"

    # Clone the repo
    echo -e "${GREEN}Cloning ${repo}${NO_COLOR}"
    git clone "https://$BITBUCKET_USERNAME@bitbucket.org/$full_repo_path"
    # Remove any carriage return characters from the repo name
    repo=$(echo "$repo" | tr -d '\r')
    # Change to the cloned directory if it exists, otherwise display an error message
    cd "$repo" || {
        echo "Failed to change to directory: $repo"
        return
    }

    # Create the repo on GitHub
    gh repo create "$GITHUB_ORG/$repo" --private --source=. --remote=upstream --team "$GITHUB_TEAM"
    gh api -X PUT "/orgs/$GITHUB_ORG/teams/$GITHUB_TEAM/repos/$GITHUB_ORG/$repo" -f 'permission=admin' 1>/dev/null

    # Update the remote URL
    git remote set-url origin "https://github.com/$GITHUB_ORG/$repo.git"

    # Create a new branch with the name of the default branch
    git checkout -b "$GITHUB_DEFAULT_BRANCH"

    # Check if the old default branch exists
    if git show-ref --verify --quiet refs/heads/"$BITBUCKET_DEFAULT_BRANCH"; then
        # Merge the old default branch into the new default branch without committing or fast-forwarding
        git merge "$BITBUCKET_DEFAULT_BRANCH" --no-commit --no-ff
        # Commit the changes with a message
        git commit -am "Move everything to $GITHUB_DEFAULT_BRANCH branch"
    fi

    # Push the default branch to GitHub
    echo -e "${GREEN}Pushing ${repo} to GitHub.${NO_COLOR}"
    git push origin "$GITHUB_DEFAULT_BRANCH"

    # Loop through all branches from origin
    echo -e "${GREEN}Adding all other branches from ${repo}.${NO_COLOR}"
    git branch -r | grep -v HEAD | grep -v master | grep -v "$GITHUB_DEFAULT_BRANCH" | awk '{print $1}' | while read -r branch; do
        # Remove 'origin/' prefix from the branch name
        local_branch=$(echo "$branch" | sed 's/^origin\///')
        # Switch to the branch
        git checkout "$local_branch" || {
            echo "Failed to checkout $local_branch"
            continue
        }
        # Push the branch back to GitHub
        git push origin "$local_branch" || {
            echo "Failed to push $local_branch"
            continue
        }
    done
    cd ..
}

# Migrate the repos in parallel
for repo in "${repos_to_migrate[@]}"; do
    migrate_repo "$repo" &
done

# Wait for all background jobs to finish
wait

echo -e "${GREEN}All repositories have been migrated.${NO_COLOR}"
