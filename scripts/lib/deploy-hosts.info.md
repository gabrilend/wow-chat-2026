# deploy-hosts.lua

Reads and checks the roles file, `config/deploy-hosts.lua`, which says
which machine does each of the server's jobs: `database`, `auth`, `world`
(issue 157a). A role is `"local"` (the development machine itself) or a
table describing its machine: `lan_address` (dotted IPv4), `ssh_user`,
`install_dir` (absolute path), `arch` (as `uname -m` says it). Its command
line face is `scripts/deploy-host`; its test is `scripts/test-deploy-hosts`.

## Functions

### `Hosts.load(path) -> hosts | nil, err`
Runs the roles file with nothing to call (it can only build its table; a
compiled file is refused) and returns the table it returns. Errors name the
file.

### `Hosts.problems(hosts) -> list of sentences`
Every mistake, empty when there are none: a role missing or unknown; a
role neither `"local"` nor a table; a field missing, unknown or malformed
(an address with a number over 255 or a leading zero, a loopback address
that should be `"local"`, 0.x.x.x; a user name that isn't lower-case
letters, digits, `_` and `-`, up to 32; a folder that isn't absolute, is
`/`, goes up with `..` or has a space; an unknown architecture). Two roles
may share an address (one machine), but must agree on its architecture
with the first role named at it.

### `Hosts.field(hosts, role, field, here) -> text | nil, why`
One field of one role. Besides the four fields, `local` answers `yes` or
`no`. A local role answers this machine's own: `127.0.0.1`, an empty user
(no ssh), `here.dir` and `here.arch`.
