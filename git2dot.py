import click
import git

from graphviz import Digraph
from itertools import chain


@click.command()
@click.option('-o', '--output')
@click.option('-r', '--render', is_flag=True)
@click.option('-v', '--view', is_flag=True)
@click.option('-f', '--format', default='svg')
@click.option('-m', '--use-message', is_flag=True)
@click.option('-g', '--gather', type=click.Choice(['free', 'commit', 'branch']),
              default='free')
@click.option('--shortref-len', default=10)
@click.option('--exclude-remote', '--xr', multiple=True, default=[])
@click.option('--exclude-tag', '--xt', multiple=True, default=[])
@click.option('--exclude-branch', '--xb', multiple=True, default=[])
@click.option('--remote/--no-remote', '-R', 'flag_remote')
@click.option('--tags/--no-tags', '-t', 'flag_tags')
@click.option('--rankdir', default='TB')
def main(output, render, view, format, flag_remote, flag_tags,
         rankdir, use_message, gather, shortref_len,
         exclude_remote, exclude_tag, exclude_branch):

    def _shortref(ref):
        return ref.hexsha[:shortref_len]

    if (render or view) and not output:
        raise click.ClickException('--render and --view require --output')

    repo = git.Repo()
    seen = set()

    graph = Digraph(name='git', format='svg',
                    graph_attr=dict(rankdir=rankdir),
                    node_attr=dict(shape='circle'),
                    )

    # subgraph for local branch heads
    heads = Digraph(node_attr=dict(
        group='heads', shape='box', color='black', style='filled', fontcolor='white',
    ))

    # one subgraph per branch when using -g, otherwise just a funny
    # container for a single subgraph.
    commits = []

    branch_links = set()
    commit_links = set()
    tag_links = set()

    for head in repo.heads:
        if head.name in exclude_branch:
            continue

        heads.node(head.name)
        branch_links.add((head.name, _shortref(head.commit)))

        if gather == 'branch':
            sub = Digraph(node_attr=dict(group=f'{head.name}_commits'))
            commits.append(sub)
        elif not commits and gather == 'commit':
            sub = Digraph(node_attr=dict(group='commits'))
            commits.append(sub)
        elif not commits and gather == 'free':
            sub = graph
            commits.append(sub)
        else:
            sub = commits[0]

        for commit in chain([head.commit], head.commit.traverse()):
            if commit in seen:
                continue
            seen.add(commit)

            args = dict(tooltip=commit.message.splitlines()[0])

            if use_message:
                msg = commit.message.splitlines()[0]
                args['label'] = msg
            sub.node(_shortref(commit), **args)

            for parent in commit.parents:
                commit_links.add((_shortref(commit), _shortref(parent)))

    if gather != 'free':
        for sub in commits:
            graph.subgraph(sub)

    graph.subgraph(heads)

    if flag_remote:
        # subgraph for remote heads
        remote_heads = Digraph(node_attr=dict(
            group='remote_heads', shape='box', color='grey', style='filled',
            fontcolor='white',
        ))

        for remote in repo.remotes:
            if remote.name in exclude_remote:
                continue

            for ref in remote.refs:
                remote_heads.node(ref.name)
                branch_links.add((ref.name, _shortref(ref.commit)))
        graph.subgraph(remote_heads)

    if flag_tags:
        # subgraph for tags
        tags = Digraph(node_attr=dict(
            group='tags', shape='cds', color='#87f542', style='filled',
            fontcolor='black',
        ))

        for tag in repo.tags:
            if tag.name in exclude_tag:
                continue

            tags.node(tag.name)
            tag_links.add((tag.name, _shortref(tag.commit)))
        graph.subgraph(tags)

    if branch_links:
        with graph.subgraph(edge_attr=dict(style='dashed')) as sub:
            sub.edges(branch_links)

    if tag_links:
        with graph.subgraph(edge_attr=dict(style='dashed')) as sub:
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
