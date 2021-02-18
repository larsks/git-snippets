import click
import git

from graphviz import Digraph


@click.command()
@click.option('-o', '--output')
@click.option('-r', '--render', is_flag=True)
@click.option('-v', '--view', is_flag=True)
@click.option('-f', '--format', default='svg')
@click.option('-m', '--use-message', is_flag=True)
@click.option('-g', '--gather-by-branch', is_flag=True)
@click.option('--remote/--no-remote', '-R', 'flag_remote')
@click.option('--tags/--no-tags', '-t', 'flag_tags')
@click.option('--rankdir', default='TB')
def main(output, render, view, format, flag_remote, flag_tags,
         rankdir, use_message, gather_by_branch):
    if (render or view) and not output:
        raise click.ClickException('--render and --view require --output')

    repo = git.Repo()
    seen = set()

    graph = Digraph(name='git', format='svg')
    graph.attr(rankdir=rankdir)

    commits = []

    heads = Digraph()
    heads.node_attr = dict(
        group='heads', shape='box', color='black', style='filled', fontcolor='white',
    )

    remote_heads = Digraph()
    remote_heads.node_attr = dict(
        group='remote_heads', shape='box', color='grey', style='filled', fontcolor='white',
    )

    tags = Digraph()
    tags.node_attr = dict(
        group='tags', shape='cds', color='#87f542', style='filled', fontcolor='black',
    )

    branch_links = []
    commit_links = []
    tag_links = []

    for head in repo.heads:
        heads.node(head.name)
        branch_links.append((head.name, head.commit.hexsha[:10]))

        if gather_by_branch or not commits:
            sub = Digraph()
            sub.node_attr = dict(group=f'{head.name}_commits')
            commits.append(sub)
        elif not gather_by_branch:
            sub = commits[0]

        for commit in [head.commit] + list(head.commit.traverse()):
            if commit in seen:
                continue

            args = dict(tooltip=commit.message.splitlines()[0])

            if use_message:
                msg = commit.message.splitlines()[0]
                args['label'] = msg
            sub.node(commit.hexsha[:10], **args)
            seen.add(commit)

            for parent in commit.parents:
                if (commit, parent) in seen:
                    continue
                commit_links.append((commit.hexsha[:10], parent.hexsha[:10]))

    for sub in commits:
        graph.subgraph(sub)
    graph.subgraph(heads)

    if flag_remote:
        for remote in repo.remotes:
            for ref in remote.refs:
                remote_heads.node(ref.name)
                branch_links.append((ref.name, ref.commit.hexsha[:10]))
        graph.subgraph(remote_heads)

    if flag_tags:
        for tag in repo.tags:
            tags.node(tag.name)
            tag_links.append((tag.name, f'{tag.commit.hexsha[:10]}'))
        graph.subgraph(tags)

    if branch_links:
        with graph.subgraph() as sub:
            sub.edge_attr = dict(style='dashed')
            sub.edges(branch_links)

    if tag_links:
        with graph.subgraph() as sub:
            sub.edge_attr = dict(style='dashed')
            sub.edges(tag_links)

    graph.edges(commit_links)

    if not output:
        print(graph.source)
    else:
        if format == 'dot':
            with open(output, 'w') as fd:
                fd.write(graph.source)
        else:
            graph.render(filename=output, view=view, format=format)


if __name__ == '__main__':
    main()
