import click
import git
import json

from dataclasses import dataclass, field


@dataclass
class Graph:
    name: str

    nodes: list = field(default_factory=list)
    edges: list = field(default_factory=list)

    def __str__(self):
        return '\n'.join([
            f'digraph "{self.name}" {{',
            '\n'.join(str(node) for node in self.nodes),
            '\n'.join(str(edge) for edge in self.edges),
            '}'
        ])


@dataclass
class Node:
    name: str
    shape: str = field(default="ellipse")
    tooltip: str = field(default=None)

    def __str__(self):
        return (
            f'"{self.name}" [' +
            (f'shape={self.shape} ' if self.shape else '') +
            (f'tooltip={json.dumps(self.tooltip)} ' if self.tooltip else '') +
            ']'
        )


@dataclass
class Edge:
    a: Node
    b: Node

    def __str__(self):
        return f'"{self.a}" -> "{self.b}"'


@click.command()
def main():
    repo = git.Repo()
    seen = set()

    graph = Graph('git')
    for head in repo.heads:
        graph.nodes.append(Node(name=head.name, shape='box'))
        graph.edges.append(Edge(a=head.name, b=head.commit.hexsha[:10]))

        for commit in [head.commit] + list(head.commit.traverse()):
            if commit in seen:
                continue

            graph.nodes.append(Node(name=commit.hexsha[:10],
                                    tooltip=commit.message.splitlines()[0]))
            seen.add(commit)

            for parent in commit.parents:
                if (commit, parent) in seen:
                    continue
                graph.edges.append(Edge(a=commit.hexsha[:10], b=parent.hexsha[:10]))

    print(graph)


if __name__ == '__main__':
    main()
