#!/bin/bash

# The name of the organization whose repositories you want to manage
ORG_NAME="odevo-dev"

# Space-separated list of repositories to keep
KEEP_REPOS="skills kw.cypresstests-gustav"

# Convert the space-separated list into an array
IFS=' ' read -r -a REPO_ARRAY <<<"$KEEP_REPOS"

# Get a list of all repositories in the organization
repos=()
while IFS= read -r line; do
    repos+=("$line")
done < <(gh repo list $ORG_NAME -L 100 | awk '{print $1}')

# Array to hold repos to delete
repos_to_delete=()

# Loop through each repo and check if it's not one of the ones to keep
for repo in "${repos[@]}"; do
    repo_name=$(basename "$repo")
    found=0

    for keep_repo in "${REPO_ARRAY[@]}"; do
        if [[ "$keep_repo" == "$repo_name" ]]; then
            found=1
            break
        fi
    done

    if ((found == 0)); then
        repos_to_delete+=("$repo")
    fi
done

# Check if there are repos to delete
if [ ${#repos_to_delete[@]} -eq 0 ]; then
    echo "No repos found to delete."
    exit 0
fi

# Show the repos to be deleted and ask for confirmation
echo "The following repos will be deleted:"
for repo in "${repos_to_delete[@]}"; do
    echo "$repo"
done

read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Delete the repos
for repo in "${repos_to_delete[@]}"; do
    echo "Deleting $repo..."
    gh repo delete "$repo" --yes
done

# Remove the "repos" directory
if [ -d "repos" ]; then
    echo "Removing repos directory..."
    rm -rf "repos"
fi
