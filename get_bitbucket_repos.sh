#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "ERROR: .env file not found."
    exit 1
fi

# Check if required variables are set
if [ -z "$BITBUCKET_USERNAME" ]; then
    echo "ERROR: BITBUCKET_USERNAME is missing in the .env file."
    exit 1
fi

if [ -z "$BITBUCKET_APP_PASSWORD" ]; then
    echo "ERROR: BITBUCKET_APP_PASSWORD is missing in the .env file."
    exit 1
fi

if [ -z "$BITBUCKET_ORG" ]; then
    echo "ERROR: BITBUCKET_ORG is missing in the .env file."
    exit 1
fi

# Fetch repositories from Bitbucket API
response=$(curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD" "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_ORG")

# Check if API call was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to fetch repositories from Bitbucket"
    exit 1
fi

# Check if the response is empty or contains errors
if [ -z "$response" ]; then
    echo "ERROR: Empty response from API"
    exit 1
fi

# Initialize an empty array to store the repo names
repo_names=()

# Loop through repositories and add names to the array
while IFS= read -r name; do
    repo_names+=("$name")
done < <(echo "$response" | jq -r '.values[].name')

# Pagination: handle next page URLs
NEXT_URL=$(echo "$response" | jq -r '.next')

while [[ "$NEXT_URL" != "null" && "$NEXT_URL" != "" ]]; do
    response=$(curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD" "$NEXT_URL")

    # Check if API call was successful
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to fetch repositories from $NEXT_URL"
        exit 1
    fi

    # Check if the response is empty or contains errors
    if [ -z "$response" ]; then
        echo "ERROR: Empty response from API"
        exit 1
    fi

    # Loop through repositories and add names to the array
    while IFS= read -r name; do
        repo_names+=("$name")
    done < <(echo "$response" | jq -r '.values[].name')

    # Get next page URL for pagination
    NEXT_URL=$(echo "$response" | jq -r '.next')
done

# Print all repo names separated by spaces
echo "${repo_names[*]}"
