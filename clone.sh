#!/bin/bash

# Color definitions
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

# Function to print error and exit
fail() {
    echo -e "${RED}$1${RESET}"
    exit "${2:-1}"
}

# Check required dependencies
for dep in python jq; do
    command -v "$dep" > /dev/null || fail "$dep is not installed. Exiting..."
done

# Check for sources.yaml file
[ -f "sources.yaml" ] || fail "sources.yaml file not found. Exiting..."

# Get version from environment variable
version=${VERSION}

# Check if version is provided and valid
if [ -z "$version" ]; then
    fail "No version specified. No kernel or clang will be cloned. Exiting..."
fi

if ! [[ "$version" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    fail "Invalid version format. Exiting..."
fi

# Convert YAML to JSON
json=$(python -c "import sys, yaml, json; json.dump(yaml.safe_load(sys.stdin), sys.stdout)" < sources.yaml) || fail "Failed to convert YAML to JSON."

# Parse kernel and clang commands for the given version
kernel_commands=$(echo "$json" | jq -r --arg version "$version" '.[$version].kernel[]') || fail "Could not parse kernel commands."
clang_commands=$(echo "$json" | jq -r --arg version "$version" '.[$version].clang[]') || fail "Could not parse clang commands."

# Function to print commands with color
print_commands() {
    local commands="$1"
    echo "$commands" | while read -r command; do
        [ -n "$command" ] && echo -e "${GREEN}$command${RESET}"
    done
}

# Function to execute commands with a path argument
execute_commands() {
    local commands="$1"
    local path="$2"
    echo "$commands" | while read -r command; do
        [ -n "$command" ] && bash -c "$command $path"
    done
}

# Print commands that will be executed
echo -e "${RED}Clone.sh will execute the following commands corresponding to ${version}:${RESET}"
print_commands "$kernel_commands"
print_commands "$clang_commands"

# Execute kernel and clang commands
execute_commands "$kernel_commands" "kernel"
execute_commands "$clang_commands" "kernel/clang"
