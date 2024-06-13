#!/bin/bash

# The name of the organization whose repositories you want to manage
ORG_NAME="odevo-dev"

# Space-separated list of repositories to keep
KEEP_REPOS="skills kw.cypresstests-gustav"

# Convert the space-separated list into an array
IFS=' ' read -r -a REPO_ARRAY <<<"$KEEP_REPOS"

# Get a list of all repositories in the organization
IFS=$'\n' repos=("$(gh repo list -L 100 $ORG_NAME | awk '{print $1}')")

# Loop through each repo and delete it if it's not one of the ones to keep
for repo in "${repos[@]}"; do
    repo_name=$(basename $repo)
    if [[ ! " ${REPO_ARRAY[@]} " =~ " $repo_name " ]]; then
        echo "Deleting $repo..."
        gh repo delete "$repo" --yes
    else
        echo "Keeping $repo."
    fi
done

# Remove the "repos" directory
if [ -d "repos" ]; then
    echo "Removing repos directory..."
    rm -rf "repos"
fi
