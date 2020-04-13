#! /usr/bin/env python3
import sys
import argparse
from ete3 import Tree


parser = argparse.ArgumentParser(
    description='Newick tree to Graphviz dot',
    formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument(
    '-n', '--newick', help="The newick tree to reformat",
    action="store_true", default="-")

parser.add_argument(
    '-m', '--mirror', help="emit child -> parent", action="store_true", default=False)

args = parser.parse_args()

if args.newick == "-":
    args.newick = next(sys.stdin)  # only single line piped to stdin to begin with

tree = Tree(args.newick)
root = tree.get_tree_root()


def traverse(parent):
    if parent.name is None or parent.name == '':
        if args.mirror:
            parent_id = 0
        else:
            parent_id = 1
    else:
        (parent_name, parent_id) = parent.name.split(r' - ')
        print(f'txid_{parent_id}[label="{parent_name}"];')

    for child in parent.get_children():
        (child_name, child_id) = child.name.split(r' - ')
        if args.mirror:
            print(f'txid_{child_id} -> txid_{parent_id};')
        else:
            print(f'txid_{parent_id} -> txid_{child_id};')

        # hard coding the taxon to hilite is an expediant while experimenting...I hope
        if child.is_leaf():
            if child_id in ("9606", "2697049"):
                print(f'txid_{child_id}[label="{child_name}", color="green",style="filled", shape="record"];')
            else:
                print(f'txid_{child_id}[label="{child_name}"];')
        else:
            traverse(child)


if __name__ == '__main__':
    print('digraph G { rankdir = "LR"')
    traverse(root)
    print('}')
