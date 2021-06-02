OPTS_SPEC="\
${0##*/} [<options>] <ref>

Replace a commit message with the content of the specified
file (or stdin if unspecified).
--
h,help    Show the help

a,all           Update all branches from which the commit is reachable
v,verbose       Increase logging verbosity
F,message-file= get message from file instead of stdin
"

all_branches=0

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
    (-a)    all_branches=1
            shift
            ;;

    (-v)    let verbose+=1
            shift
            ;;

    (-F)    message_file=$2
            shift 2
            ;;

    (--)    shift
            break
            ;;

    (-*)    DIE "unknown option: $1"
            ;;
    esac
done

(( $# == 1 )) || DIE "missing refspec"
target=$1

# get the current branch name
branch=$(git rev-parse --symbolic-full-name HEAD)
[[ $branch = HEAD ]] && DIE "unable to determine branch name"

# git the full commit id of our target commit (this allows us to
# specify the target as a short commit id, or as something like
# `HEAD~3` or `:/interesting`.
oldref=$(git rev-parse --verify "$target") || DIE "invalid reference: $target"

if (( all_branches )); then
  branch_list=($(git branch --contains $oldref --format='%(refname)'))
else
  branch_list=($branch)
fi

for branch in "${branch_list[@]}"; do
  LOG 1 "checking branch $branch"

  # verify that target is an ancestor of current HEAD
  git merge-base --is-ancestor $oldref $branch ||
    DIE "$target ($oldref) is reachable from $branch but is not an ancestor of $branch"

  # check for merge commits
  git log --format='%p' $oldref..$branch | awk 'NF>1 {exit 1}' ||
    DIE "history contains one or more merge commits"
done

# generate a replacement commit object, reading the new commit message
# from stdin.
newref=$(
(git cat-file -p $oldref | sed '/^$/q'; cat $message_file) |
  git hash-object -t commit --stdin -w
)
echo $newref

# iterate over commits between our target commit and HEAD in
# reverse order, replacing parent points with updated commit objects
for branch in "${branch_list[@]}"; do
  LOG 0 "updating branch $branch"
  for rev in $(git rev-list --reverse ${oldref}..$branch); do
    LOG 2 "updating rev $rev"
    newref=$(git cat-file -p $rev |
      sed "1,/^$/ {/^parent/ s/$oldref/$newref/}" |
      git hash-object -t commit --stdin -w)
    oldref=$rev
  done

  # update the branch pointer to the head of the modified tree
  git update-ref $branch $newref
done
