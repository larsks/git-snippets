import click
import git


# XXX: this is wrong. It will only modify the parents of one commit,
# so if there were multiple commits with the target as a parent the
# resulting repository history will not be correct.
#
# Or maybe not: git-revise simply refuses to edit a commit in this
# situation, and git-rebase linearizes the history.
def replace(commit, target, seen=None, **kwargs):
    '''update commit <target>

    traverse tree looking for target, then make any requested changes.

    ensure we visit each node only once
    '''

    if seen is None:
        seen = set()

    seen.add(commit)

    if commit == target:
        new = commit.replace(**kwargs)
        return new

    parents = [
        replace(parent, target=target, seen=seen, **kwargs)
        for parent in commit.parents
    ]

    return commit.replace(parents=parents)


@click.command()
@click.option('-m', '--message', required=True)
@click.argument('target')
def main(message, target):
    repo = git.Repo()
    branch = repo.active_branch
    target = repo.commit(target)
    cur = repo.head.commit

    print('old:', branch.commit)
    new = replace(cur, target, message=message)
    branch.set_commit(new)
    print('new:', branch.commit)


if __name__ == '__main__':
    main()
