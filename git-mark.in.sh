OPTS_SPEC="\
${0##*/} [<options>] [<ref> [...]]

Mark or unmark the subject line of the named commits
(or HEAD if unspecified).
--
h,help          Show the help

m,mark          Add the mark
u,unmark        Remove the mark
M,set-mark=MARK Set the mark to MARK
v,verbose       Increase logging verbosity
"

mark=$(git config --get --default WIP mark.default)

case $0 in
    (*unmark)
        mode=unmark
        ;;

    (*)
        mode=mark
        ;;
esac

eval "$(git rev-parse --parseopt -- "$@" <<<$OPTS_SPEC || echo exit $?)"

while (( $# > 0 )); do
    case $1 in
    (-u)    mode=unmark
            shift
            ;;

    (-m)    mode=mark
            shift
            ;;

    (-M)    mark=$2
            shift 2
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

tmpdir=$(mktemp -d commitXXXXXX)
trap "rm -rf $tmpdir" EXIT

for refspec in "${@:-HEAD}"; do
    rev=$(git rev-parse --verify -q ${refspec})
    [[ $rev ]] || DIE "invalid refspec: $refspec"

    LOG 2 "processing $refspec ($rev)"

    git cat-file -p $rev | sed '1,/^$/d' | tee $tmpdir/modified > $tmpdir/orig
    if [[ $mode == mark ]]; then
        if ! sed -n 1p $tmpdir/orig | grep -q '\['"$mark"']'; then
            sed '1 s/^/['"$mark"'] /' $tmpdir/orig > $tmpdir/modified
        fi
    else
        sed '1 s/^\['"$mark"'] //' $tmpdir/orig > $tmpdir/modified
    fi

    if ! diff $tmpdir/orig $tmpdir/modified > /dev/null; then
        LOG 0 "modifying commit $refspec (${rev:0:10})"
        git set-message -F $tmpdir/modified $rev > $tmpdir/out 2> $tmpdir/err ||
            DIE "failed to modify mark: $(cat $tmpdir/err)"
        git show -q $(cat $tmpdir/out)
    fi
done
