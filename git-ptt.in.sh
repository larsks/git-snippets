OPTS_SPEC="\
${0##*/} [<options>] <refspec>

Push a series of commits to multiple remote branches based
on their x-branch trailer.
--
h,help          Show the help

q,query         Show targets but do not push
f,force         Push using --force-with-lease
F,FORCE         Push using --force
v,verbose       Increase logging verbosity
r,remote=REMOTE Push to remote <REMOTE>
"

force=
remote=$(git config --get --default origin ptt.remote)
query_only=0
shortlen=10
marker=x-branch

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
    (-f)    force="--force-with-lease"
            shift
            ;;

    (-F)    force="--force"
            shift
            ;;

    (-r)    remote="$2"
            shift 2
            ;;

    (-q)    query_only=1
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
shift $(( OPTIND - 1 ))

(( $# == 1 )) || DIE "missing refspec"

for rev in $(git rev-list "$1" | tac ); do
    LOG 2 "processing $rev"

    target=($(git show $rev -q --format="%(trailers:key=${marker},valueonly=true)"))

    if (( ${#target[*]} > 1 )); then
        DIE "multiple ${marker} directives in $rev"
    elif (( ${#target[*]} == 0 )); then
        continue
    fi

    target_rev=$(git rev-parse --verify -q ${remote}/${target} || echo none)

    if [[ $target_rev == $rev ]]; then
        target_rev_color=green
    else
        target_rev_color=red
    fi
    target_rev_fmt="%C${target_rev_color}${target_rev:0:$shortlen}%Creset"
    rev_fmt="${rev:0:$shortlen}"

    git show -q --format="* %s%n  ${rev_fmt} -> ${target_rev_fmt} %Cblue${remote}/${target}%Creset" $rev
    (( $query_only )) && continue
    git push ${force} ${remote} ${rev}:refs/heads/${target}
done
