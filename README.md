# Git Stress

Automatic Git Repository Generator

## Introduction

This is a simple shell script for automatically generating Git repositories for
uses such as the testing of Git tools. The files it creates are very simple at
the moment and don't make a very realistic repository; however, it can generate
large numbers of changes with branches, tags and merges - already enough to
trouble repository browsers and visualisation tools.

## Usage

It's a shell script called in the following fashion:

    ./stress.bash -n 1000 my_repo

That would create a repository called `my_repo` and perform a thousand
operations on it.

## Options

The script is called with the following syntax:

    ./stress.bash [<options>] <repo_name>

Where `repo_name` is a mandatory parameter and everything else is optional.

The script takes a small number of command-line options at present:

    -h or -?    Display usage information
    -n <number> Number of operations to perform (default 30)
    -d <path>   Path to a dictionary file (default /usr/share/dict/words)

## How It Works

The script first creates a repository and adds itself to that repository in the
initial commit. It then creates three randomly-named files to begin with, each
containing a random word. After that, it performs the number of operations
specified before exiting.

Each operation begins with the generation of a random number from 0 to 99.
This number is used to weight the type of operations taking place - content
change commits are naturally more frequent than branch creations and merges.

### Operations

*Create File* (frequency around 2%) adds a new file to the repository in the
current branch. The file name is picked at random and a random word is inserted
into the file.

*Create Tag* (frequency around 5%) tags the head of the current branch. An
extra random choice is made - around 50% of the tags created will be annotated
tags.

*Create Branch* (frequency around 10%) creates a new branch from master. The
branch name is chosen at random.

*Switch Branch* (frequency around 15%) checks out a randomly-selected branch
other than the current one. This is to try to make the repository history a bit
more interesting.

*Merge Branch* (frequency around 5%) merges the current branch into master. It
always creates a merge commit to keep the history looking nice (it will not do
a fast-forward merge). Any conflicts arising are resolved by removing the
conflict markers and committing the unique lines from the resulting files. This
isn't entirely realistic but it means there'll be enough merges to make the
history interesting.

*Modify Content* (the remainder, around 63%) selects a random subset of the
files in the current branch for modification. It then adds a random word to
each of the selected files and commits the results. The average size of the
commits will naturally grow as the repository grows, which is probably
a reasonable reflection of real repositories.

## Future Plans

There are undoubtedly portability bugs as I've only been using it locally (Mac
OS X). The probability weightings of the different operations should be
configurable. The content modification operations should also delete lines and
should sometimes insert rather than append. Files should sometimes be removed.
Basically, it should better reflect real repository characteristics.

I'd like to add other operations (cherry-picks, notes, forced commits, signed
commits) because they're also useful test data when playing with visualisation
tools. Handling of binary files would possibly be useful too.

Suggestions, bug reports and patches all welcome:
[git-stress](https://github.com/threebytesfull/git-stress)

## License

git-stress is released under the MIT license. See
[LICENSE.md](https://github.com/threebytesfull/git-stress/blob/master/LICENSE.md)
