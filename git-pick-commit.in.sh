OPTS_SPEC="\
${0##*/} [<options>] [<pattern>]

Select a commit using fzf.
--
h,help          Show the help

c,checkout          Pass selection to 'git checkout'
"

checkout=0
fzf_opts=()

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
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


git log --format='%h %s' --abbrev=10 |
    fzf "${fzf_opts[@]}" --preview='git show -q {1}' |
    awk '{print $1}'
