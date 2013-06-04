#!/bin/bash

num_commits=30
dict_file=/usr/share/dict/words

num_words=$(wc -l $dict_file | awk '{print $1}')
word_num=1
branch_level=0

die() {
    local msg=$1
    echo "Fatal error: $msg" >&2
    exit 1
}

chance() {
    echo $(( $RANDOM % 100 ))
}

big_random() {
    echo $(( ( $RANDOM << 15 ) + $RANDOM ))
}

random_word() {
    word_num=$(( ( ($word_num + $(big_random)) % $num_words) + 1 ))
    head -n $word_num $dict_file | tail -n 1
}

random_op() {
    local op_num=$1
    local which_op=$(chance)
    if [ $which_op -lt 5 ]; then
        do_tag $op_num
    elif [ $which_op -lt 15 ]; then
        do_branch $op_num
    elif [ $which_op -lt 30 ] && [ $(num_branches) -gt 0 ]; then
        do_checkout $op_num
    elif [ $which_op -lt 35 ] && [ $branch_level -gt 0 ]; then
        do_merge $op_num
    elif [ $which_op -lt 37 ]; then
        do_new_file $op_num
    else
        do_commit $op_num
    fi
}

list_branches() {
    git branch | grep -v '^\*' | awk '{ print $1 }'
}

num_branches() {
    list_branches | wc -l | awk '{ print $1 }'
}

current_branch() {
    git branch | grep '^\*' | awk '{ print $2 }'
}

list_files() {
    git ls-tree --name-only HEAD | grep -v "$script_name"
}

num_files() {
    list_files | wc -l | awk '{ print $1 }'
}

pick_file() {
    list_files | head -n $(( ($(big_random) % $(num_files)) + 1 )) | tail -n 1
}

do_new_file() {
    local op_num=$1
    local filename=$(random_word).txt
    echo $(random_word) >> $filename
    git add "$filename"
    git commit -m "Added new file $filename"
}

do_branch() {
    local op_num=$1
    # increment branch level counter
    branch_level=$(( $branch_level + 1 ))
    # pick branch name
    local branch_name=$(random_word)
    # pick branch source
    local branch_source='master'
    # create branch
    git checkout -b "$branch_name" "$branch_source"
}

do_commit() {
    local op_num=$1
    # pick random number of changes
    local num_changes=$(( ($(big_random) % $(num_files)) + 1 ))
    # for each change...
    while [ $num_changes -gt 0 ]; do
        # pick random word
        local word=$(random_word)
        # pick random file
        local file=$(pick_file)
        # add word to the file
        echo $word >> $file
        # decrement change counter
        num_changes=$(( $num_changes - 1 ))
    done
    # commit
    git add .
    git commit -m "Change text content ($op_num)"
}

do_checkout() {
    local op_num=$1
    # pick branch to checkout
    local branch_num=$(( ($(big_random) % $(num_branches)) + 1 ))
    local branch_name=$(list_branches | head -n $branch_num | tail -n 1)
    # checkout branch
    git checkout "$branch_name"
}

do_merge() {
    local op_num=$1
    # decrement branch level
    branch_level=$(( $branch_level - 1 ))
    # pick branch to merge
    branch_to_merge=$(current_branch)
    # merge branch
    git checkout master
    git merge --no-ff --no-edit "$branch_to_merge"
    if [ $? -ne 0 ]; then
        # fix merge conflicts
        local conflict_file
        for conflict_file in $(git status | grep 'both modified:' | awk '{ print $4 }'); do
            mv "$conflict_file" "$conflict_file.orig"
            sed -E '/^(<|=|>){7}/ d' < "$conflict_file.orig" | uniq > "$conflict_file"
            rm "$conflict_file.orig"
            git add "$conflict_file"
        done
        git commit --no-edit
    fi
}

do_tag() {
    local op_num=$1
    # choose tag name
    local tag_name="v$op_num"
    # decide what kind of tag to create
    if [ $(chance) -lt 50 ]; then
        # regular tag
        git tag "$tag_name"
    else
        # annotated tag
        git tag -a -m "Creating '$tag_name' tag" "$tag_name"
    fi
}

usage() {
    local status=$1
    echo "Usage: $0 [<options>] <repository_name>"
    echo
    echo 'Options:'
    echo
    echo '    -h | -?      Help (this usage message)'
    echo '    -n <number>  Number of operations to perform'
    echo '    -d <dict>    Path to dictionary file to use'
    echo
    exit $status
}

[ $# -lt 1 ] && usage 1

while getopts n:d:h opt; do
    echo "CHECKING OPTION $opt ($OPTARG)"
    case "$opt" in
        n)
            num_commits=$OPTARG
            shift 2
            ;;
        d)
            dict_file=$OPTARG
            shift 2
            ;;
        h|\?)
            usage 0
            shift 1
            ;;
        *)
            usage 1
            shift 1
            ;;
    esac
done

repo_name=$1

[ -e $repo_name ] && die "Refusing to overwrite existing '$repo_name'"

(
    mkdir $repo_name || die "Failed to create directory '$repo_name'"
    cp $0 $repo_name
    cd $repo_name
    git init
    git add .
    git commit -m 'Initial commit'
    script_name=$(git ls-tree --name-only HEAD)
    do_new_file
    do_new_file
    do_new_file

    for n in $(seq 1 $num_commits); do
        random_op $n
    done
)
