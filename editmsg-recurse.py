import click
import git


def clone_commit(old, **kwargs):
    md = dict(
        message=old.message,
        parent_commits=old.parents,
        author=old.author,
        committer=old.committer,
        author_date=old.authored_datetime,
        commit_date=old.committed_datetime
    )

    md.update(kwargs)

    return git.Commit.create_from_tree(
        old.repo, old.tree, **md)


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
        new = clone_commit(commit, **kwargs)
        return new

    parents = list(commit.parents)
    for i, parent in enumerate(parents):
        parents[i] = replace(parent, target=target, seen=seen, **kwargs)

    return clone_commit(commit, parent_commits=parents)


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
