import click
import git


def replace(commit, target=None, seen=None, **kwargs):
    '''update commit <target>

    traverse tree looking for target, then make any requested changes.

    ensure we visit each node only once
    '''

    if seen is None:
        seen = set()

    if commit.hexsha in seen:
        return commit

    seen.add(commit.hexsha)

    if commit == target:
        new = commit.replace(**kwargs)
        return new

    parents = list(commit.parents)
    for i, parent in enumerate(parents):
        parents[i] = replace(parent, target=target, seen=seen, **kwargs)

    return commit.replace(parents=parents)


@click.command()
@click.option('-m', '--message', required=True)
@click.argument('rev')
def main(message, rev):
    repo = git.Repo()
    branch = repo.active_branch
    rev = repo.commit(rev)
    cur = repo.head.commit

    print('old:', branch.commit)
    new = replace(cur, target=rev, message=message)
    branch.set_commit(new)
    print('new:', branch.commit)


if __name__ == '__main__':
    main()
