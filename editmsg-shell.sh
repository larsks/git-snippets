#!/bin/sh


target="$1"
message="${2:-Found it}"

if ! target=$(git rev-parse --verify "$target"); then
	echo "ERROR: invalid reference: $target" >&2
	exit 1
fi

if ! git merge-base --is-ancestor "$target" HEAD > /dev/null; then
	echo "ERROR: $target is not an ancestor of current HEAD" >&2
	exit 1
fi

branch_name="$(git rev-parse --symbolic-full-name HEAD)"
if [[ $branch_name = "HEAD" ]]; then
	echo "ERROR: unable to determine current branch" >&2
	exit 1
fi

# check for merge commits
if ! git log --format=%p "$target"..HEAD | awk 'NF>1 {exit 1}'; then
	echo "ERROR: this history contains a merge commit" >&2
	exit 1
fi

tmpfile=$(mktemp commitXXXXXX)
trap "rm -f $tmpfile" EXIT

# replace message and write new commit object to database
# saving hash in tmpfile
(
git cat-file -p "$target" | sed '/^$/Q'
printf "\n%s" "$message"
) | git hash-object -t commit --stdin -w > $tmpfile

oldhash=$target
newhash=$(cat $tmpfile)
echo "$oldhash -> $newhash"

# iterate over every commit between HEAD and target (in reverse)
# replacing parent with new parent
git rev-list "$target"..HEAD | tac | while read rev; do
	[[ $rev = $target ]] && continue

	newhash=$(git cat-file -p $rev | tee 1.txt |
		sed "s/parent $oldhash/parent $newhash/" | tee 2.txt |
		git hash-object -t commit --stdin -w)
	oldhash=$rev

	echo "$oldhash -> $newhash"
	echo $newhash > $tmpfile
done

# update branch pointer
git update-ref $branch_name $(cat $tmpfile)
