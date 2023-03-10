# First time
1. Setup by command `sh setup.sh`.
2. Run the command `source ~/.bashrc`.

# Usage
`sh checknode.sh [-a|f|h|i|j|q|t]`

# Examples
1. `sh checknode.sh -f`
2. `sh checknode.sh -ij`

# Options
* `-h`         : Display the help messages.
* `-v`         : Display the version.
* `-f`         : Only list the free nodes.
* `-d`         : Only list the down nodes.
* `-o`         : Only list the offline nodes.
* `-s <jobId>` : Only display the specific job id.

The followings can only work on login node.

* `-i`         : List the idle users.
* `-j`         : List the job ID and job user of each node.
* `-t`         : List the start time of each job.
* `-a`         : List the content with option `i`, `j`, and `t`.
* `-q`         : List the "showq" content.
* `-u <user>`  : Only display the specific user.
* `-l <label>` : Only display the specific user.


# Note
1. The option `q` does not work with other options. 
2. The default `.bashrc` file location is under `~/` or `/home/<USER>/`.
3. The order of the options does not matter. e.g. 'ij' is equivalent to 'ji'.
