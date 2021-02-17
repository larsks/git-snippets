import click
import git
import json

from graphviz import Digraph


@click.command()
@click.option('-o', '--output')
@click.option('-r', '--render', is_flag=True)
@click.option('-v', '--view', is_flag=True)
@click.option('-f', '--format', default='svg')
def main(output, render, view, format):
    if (render or view) and not output:
        raise click.ClickException('--render and --view require --output')

    repo = git.Repo()
    seen = set()

    graph = Digraph(name='git', format='svg')
    for head in repo.heads:
        graph.node(head.name,
                   shape='box', color='black', style='filled',
                   fontcolor='white')
        graph.edge(head.name, head.commit.hexsha[:10], style='dashed')

        for commit in [head.commit] + list(head.commit.traverse()):
            if commit in seen:
                continue

            graph.node(name=commit.hexsha[:10],
                       tooltip=commit.message.splitlines()[0])
            seen.add(commit)

            for parent in commit.parents:
                if (commit, parent) in seen:
                    continue
                graph.edge(commit.hexsha[:10], parent.hexsha[:10])

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
