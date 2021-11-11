OPTS_SPEC="\
${0##*/} [-c]

Continue working on modified files.
--
h,help          Show the help

c,commit        Use HEAD instead of the index
v,verbose       Increase logging verbosity
"

use_commit=0

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
    (-c)    use_commit=1
            shift
            ;;

    (-v)    let verbose+=1
            shift
            ;;

    (--)    shift
            break
            ;;

    (-*)    DIE "unknown option: $1"
            ;;
    esac
done

cd $(git rev-parse --show-toplevel)

ref=${1:-HEAD}

if [[ $use_commit -eq 1 ]]; then
	${VISUAL:-vim} -p $(git diff-tree --no-commit-id --name-only -r $ref)
elif ! git diff --quiet $ref; then
	${VISUAL:-vim} -p $(git diff --name-only $ref)
else
	echo "No work to resume."
fi
