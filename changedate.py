import click
import datetime
import git


@click.command()
@click.option('-d', '--date')
@click.argument('base')
def main(date, base):
    if date is None:
        date = datetime.datetime.now()
    else:
        date = datetime.datetime.fromisoformat(date)

    if '..' not in base:
        base = f'{base}..HEAD'

    repo = git.Repo()
    branch = repo.active_branch
    old_head = repo.head.commit

    for commit in repo.iter_commits(base):
        print(commit.hexsha[:7])
        repo.git.checkout(commit)
        repo.git.commit(amend=True, no_edit=True, date=date.isoformat())
        repo.git.rebase('HEAD', branch)

    new_head = repo.head.commit
    print(f'{old_head.hexsha[:7]} -> {new_head.hexsha[:7]}')


if __name__ == '__main__':
    main()
