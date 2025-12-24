#!/bin/bash

# Script to rebase this fork against upstream WLED repository
# Usage: ./update.sh [tag]
# If no tag is provided, lists the last 10 tags from upstream

set -e  # Exit on any error

readonly NODE_VERSION="22.15.1"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Function to check if upstream remote exists
check_upstream_remote() {
    if ! git remote | grep -q "^upstream$"; then
        print_warning "No 'upstream' remote found. Adding 'git remote add upstream https://github.com/Aircoookie/WLED'"
        git remote add upstream https://github.com/Aircoookie/WLED
    fi
}

# Function to list recent tags
list_tags() {
    print_info "Fetching upstream repository..."
    git fetch upstream --tags

    print_info "Last 10 tags from upstream:"
    git tag -l --sort=-version:refname | head -10
}

# Function to update to specific tag using cherry-pick approach
update_to_tag() {
    local tag=$1

    print_info "Fetching upstream repository..."
    git fetch upstream --tags

    # Check if tag exists
    if ! git tag -l | grep -q "^${tag}$"; then
        print_error "Tag '${tag}' not found in upstream repository"
        print_info "Available recent tags:"
        git tag -l --sort=-version:refname | head -10
        exit 1
    fi

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_error "You have uncommitted changes. Please commit or stash them first."
        exit 1
    fi

    # Get current branch
    current_branch=$(git branch --show-current)
    print_info "Current branch: ${current_branch}"
	if [ "${current_branch}" != "main" ]; then
		print_error "You are not on the 'main' branch. Please switch to 'main' branch first."
		exit 1
	fi

    # Get author name
    author_name="$(git config user.name)"
	print_info "Current author's name: ${author_name}"

    print_info "Finding commits authored by ${author_name}..."
    # Find commits authored by the specified author
    local unique_commits
    unique_commits=$(git log --reverse --pretty=format:"%H" --author="${author_name}" HEAD)

    if [ -z "$unique_commits" ]; then
        print_info "No commits by ${author_name} found. Simply resetting to ${tag}"
    else
        local commit_count
        commit_count=$(echo "$unique_commits" | wc -l | tr -d ' ')
        print_info "Found ${commit_count} commits by ${author_name} to preserve:"
        echo "$unique_commits" | while IFS= read -r commit; do
            if [ -n "$commit" ]; then
                echo "  $(git log --oneline -n 1 "$commit")"
            fi
        done
        echo
    fi

    print_info "This will:"
    print_info "1. Record commits authored by ${author_name}"
    print_info "2. Hard reset ${current_branch} to upstream tag ${tag}"
    if [ -n "$unique_commits" ]; then
        print_info "3. Cherry-pick the ${author_name} commits on top"
    fi

    # Confirm action
    read -p "Are you sure you want to update ${current_branch} to ${tag}? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Update cancelled"
        exit 0
    fi

    # Create a backup branch
    backup_branch="${current_branch}-backup-$(date +%Y%m%d-%H%M%S)"
    print_info "Creating backup branch: ${backup_branch}"
    git branch "${backup_branch}"

    # Hard reset to the target tag
    print_info "Hard resetting to ${tag}..."
    git reset --hard "${tag}"

    # Cherry-pick unique commits if any exist
    if [ -n "$unique_commits" ]; then
        print_info "Cherry-picking unique commits..."
		claude -p "Cherry-pick commits ${unique_commits} into the current branch and help me resolve merge conflicts by analyzing the conflicted files and making the necessary changes." \
			--append-system-prompt "You are a senior software engineer with expertise in embedded systems, C++ and Git." \
			--allowedTools "Bash,Read" \
			--permission-mode acceptEdits \
			--output-format stream-json --verbose

		# if conflicts remain
		if [ -n "$(git status --porcelain)" ]; then
			print_info "Please resolve conflicts and run 'git cherry-pick --continue'"
			print_info "Or run 'git cherry-pick --abort' to cancel"
			print_info "Backup branch available: ${backup_branch}"
			exit 1
		fi

        print_info "Successfully cherry-picked all ${author_name} commits!"
    fi

    # Update package.json version to match the new tag
    local new_version="${tag#v}"  # Remove 'v' prefix from tag
    print_info "Updating package.json version to ${new_version}..."

    if [ -f "package.json" ]; then
        sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"${new_version}\"/" package.json
        rm package.json.bak
        print_info "Updated package.json version to ${new_version}"
    else
        print_warning "package.json not found, skipping version update"
    fi

	# Push the current branch
	print_info "Pushing the current branch..."
	git push --force origin main
	print_info "Successfully pushed the current branch!"

	# Create/update tag in the local repo
	print_info "Creating tag ${tag}..."
	git tag -f "ph/${tag}"
	git push -f origin "ph/${tag}"
	print_info "Successfully created tag ${tag}!"

    print_info "Update completed successfully!"
    print_info "Your branch '${current_branch}' is now based on upstream tag '${tag}'"
    print_info "Backup branch available as: ${backup_branch}"
}

# Main script logic
main() {
    check_git_repo
    check_upstream_remote

    if [ $# -eq 0 ]; then
        # No arguments provided - list tags
        list_tags

		echo ""
		print_error "Please rerun the script with a tag: ./update.sh <tag>"
		exit 1
    elif [ $# -eq 1 ]; then
        # One argument provided - update to that tag
        update_to_tag "$1"
    else
        # Too many arguments
        print_error "Usage: $0 [tag]"
        print_info "Run without arguments to list available tags"
        print_info "Run with a tag name to rebase to that tag"
        exit 1
    fi
}

# Initialize nvm and select node
export NVM_DIR="$HOME/.nvm"
if [[ -z "$HOMEBREW_PREFIX" || ! -f "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
    print_error "nvm is not installed"
    exit 1
fi
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
nvm use "$NODE_VERSION"

main "$@"
