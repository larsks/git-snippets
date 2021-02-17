import click
import git


def replace(commit, target, seen=None, **kwargs):
    '''update commit <target>

    traverse tree looking for target, then make any requested changes.

    ensure we visit each node only once
    '''

    if seen is None:
        seen = set()

    seen.add(commit)

    if commit == target:
        commit = commit.replace(**kwargs)

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
