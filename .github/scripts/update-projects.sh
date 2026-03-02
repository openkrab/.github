#!/bin/bash

set -e  # Exit on error

ORG=${ORG:-openkrab}  # Default to openkrab

README_FILE="profile/README.md"

echo "Fetching repositories from $ORG organization..."

repos_json=$(gh repo list "$ORG" --json name,description --limit 100)

if [ $? -ne 0 ]; then
  echo "Failed to fetch repositories"
  exit 1
fi

echo "Generating Projects section markdown..."

projects_md=$(echo "$repos_json" | jq -r '.[] | select(.name != ".github") | "- [\(.name)](https://github.com/'"$ORG"'/\(.name)) - \(.description // "No description" | sub(" *🦞+$"; "")) 🦞"')

if [ -z "$projects_md" ]; then
  echo "No projects found"
  exit 0
fi

echo "Updating README.md..."

# Find the line number of "## Projects"
projects_line=$(grep -n "^## Projects" "$README_FILE" | cut -d: -f1)

if [ -n "$projects_line" ]; then
  # Find the next section or end of file
  next_section=$(tail -n +$((projects_line + 1)) "$README_FILE" | grep -n "^## " | head -1 | cut -d: -f1)
  
  if [ -n "$next_section" ]; then
    # Replace from Projects to next section
    head -n $((projects_line - 1)) "$README_FILE" > temp_readme.md
    echo "## Projects" >> temp_readme.md
    echo "" >> temp_readme.md
    echo "$projects_md" >> temp_readme.md
    tail -n +$((projects_line + next_section)) "$README_FILE" >> temp_readme.md
  else
    # Replace from Projects to end
    head -n $((projects_line - 1)) "$README_FILE" > temp_readme.md
    echo "## Projects" >> temp_readme.md
    echo "" >> temp_readme.md
    echo "$projects_md" >> temp_readme.md
  fi
  
  mv temp_readme.md "$README_FILE"
else
  echo "## Projects" >> "$README_FILE"
  echo "" >> "$README_FILE"
  echo "$projects_md" >> "$README_FILE"
fi

echo "README updated successfully."
