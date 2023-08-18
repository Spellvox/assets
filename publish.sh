#!/bin/bash

# GitHub repository details
repo_owner="Spellvox"
repo_assets="assets"
repo_js="cagedup-js"
repo_url="git@github.com:$repo_owner/$repo_js.git"
repo_js_dir=".js_tmp"

# Function to update packHash and packTag in universal.js
function update_js_file {
  js_file_path="$1"
  pack_hash="$2"
  pack_tag="$3"
  target_section="$4"  # Specify either "dev" or "stable"

  if [ "$target_section" == "dev" ]; then
    sed -i '' '/var packHash = ".*"/,/\}/ {
      /instanceId.contains("dev")/ {
        s#packHash = ".*"#packHash = "'$pack_hash'"#
        s#packTag = ".*"#packTag = "'$pack_tag'"#
      }
    }' "$js_file_path"
  elif [ "$target_section" == "stable" ]; then
    sed -i '' '/var packHash = ".*"/,/\}/ {
      /instanceId.contains("dev")/! {
        s#var packHash = ".*"#var packHash = "'$pack_hash'"#
        s#var packTag = ".*"#var packTag = "'$pack_tag'"#
      }
    }' "$js_file_path"
  else
    echo "Invalid target section. Please specify 'dev' or 'stable'."
  fi
}

git fetch

# Search for the latest -stable and -dev releases using regex
latest_stable_release=$(git tag --sort=committerdate | grep "stable" | tail -n 1)
latest_dev_release=$(git tag --sort=committerdate | grep "dev" | tail -n 1)

# Clone the repository if it doesn't exist
if [ ! -d "$repo_js_dir" ]; then
  git clone $repo_url $repo_js_dir
fi

# Update packHash and packTag in universal.js files
js_file_path="$repo_js_dir/src/network/universal.js"

if [ -n "$latest_stable_release" ]; then
  # Find the release body based on the latest -stable tag
  release_body_stable=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_assets/releases/tags/$latest_stable_release")
  # Extract the commit hash from the release body
  commit_hash_stable=$(echo "$release_body_stable" | grep -oE 'hash: [0-9a-f]+' | awk '{print $2}')
  # Now update
  update_js_file "$js_file_path" "$commit_hash_stable" "$latest_stable_release" "stable"
  echo "Updated to $commit_hash_stable [$latest_stable_release] (stable) -> $js_file_path"
fi

if [ -n "$latest_dev_release" ]; then
  # Find the release body based on the latest -dev tag
  release_body_dev=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_assets/releases/tags/$latest_dev_release")
  # Extract the commit hash from the release body
  commit_hash_dev=$(echo "$release_body_dev" | grep -oE 'hash: [0-9a-f]+' | awk '{print $2}')
  # Now update
  update_js_file "$js_file_path" "$commit_hash_dev" "$latest_dev_release" "dev"
  echo "Updated to $commit_hash_dev [$latest_dev_release] (dev) -> $js_file_path"
fi

# Push and cleanup
if [ -d "$repo_js_dir" ]; then
  cd "$repo_js_dir"
  chmod +x push.sh
  ./push.sh
  cd ..
  rm -rf "$repo_js_dir"
fi

echo "All done :)"
