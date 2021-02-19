#!/bin/sh

die() {
	echo "ERROR: $*" >&2
	exit 1
}

# get the current branch name
branch=$(git rev-parse --symbolic-full-name HEAD)
[[ $branch = HEAD ]] && die "unable to determine branch name"

# git the full commit id of our target commit (this allows us to
# specify the target as a short commit id, or as something like
# `HEAD~3` or `:/interesting`.
oldref=$(git rev-parse --verify "$1") || die "invalid reference: $1"

# verify that target is an ancestor of current HEAD
git merge-base --is-ancestor $oldref HEAD ||
	die "$1 ($oldref) is not an ancestor of current HEAD"

# check for merge commits
git log --format='%p' $oldref..HEAD | awk 'NF>1 {exit 1}' ||
	die "history contains one or more merge commits"

# generate a replacement commit object, reading the new commit message
# from stdin.
newref=$(
(git cat-file -p $oldref | sed '/^$/q'; cat) |
	git hash-object -t commit --stdin -w
)

# iterate over commits between our target commit and HEAD in
# reverse order, replacing parent points with updated commit objects
for rev in $(git rev-list --reverse ${oldref}..HEAD); do
  newref=$(git cat-file -p $rev |
    sed "s/parent $oldref/parent $newref/" |
    git hash-object -t commit --stdin -w)
  oldref=$rev
done

# update the branch pointer to the head of the modified tree
git update-ref $branch $newref

