import click
import git
import json

from graphviz import Digraph


@click.command()
def main():
    repo = git.Repo()
    seen = set()

    graph = Digraph(name='git')
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

    print(graph.source)


if __name__ == '__main__':
    main()
