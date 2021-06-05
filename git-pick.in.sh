OPTS_SPEC="\
${0##*/} [<options>] [<pattern>]

Select references using fzf.
--
h,help          Show the help

t,tags              Pick tags
b,branches          Pick local branches (this is the default)
r,remote-branches   Pick remote branches
a,all               Pick all references
m,multi             Allow multiple selections
c,checkout          Pass selection to 'git checkout'
"

checkout=0
select_branches=0
select_tags=0
select_remotes=0
fzf_opts=()

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
    (-t)    select_tags=1
            shift
            ;;

    (-b)    select_branches=1
            shift
            ;;

    (-r)    select_remotes=1
            shift
            ;;

    (-a)    select_tags=1
            select_branches=1
            select_remotes=1
            shift
            ;;

    (-m)    fzf_opts+=(-m)
            shift
            ;;

    (-c)    checkout=1
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

patterns=()

(( $select_tags + $select_branches + $select_remotes == 0 )) && select_branches=1
[[ $select_tags == 1 ]] && patterns+=(refs/tags/)
[[ $select_branches == 1 ]] && patterns+=(refs/heads/)
[[ $select_remotes == 1 ]] && patterns+=(refs/remotes/)

selected=($(
    git for-each-ref --format='%(refname)' "${patterns[@]}" |
        cut -f3- -d/ |
        fzf "${fzf_opts[@]}"
))

if [[ $checkout = 1 ]]; then
    git checkout $selected
else
    echo "${selected[@]}"
fi
