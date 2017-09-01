# PSQL.vim

This is a plugin to let you send SQL statements from vim to psql and get the results back in a vim
buffer.

## Usage

Run `:PsqlConnect` and follow the prompts to connect your buffer to a specific db. This will add the
following mappings

- `c<GR>`: Run the entire buffer and display the results
- `cp`: Run the currently selected region and display the results
- `cpp`: Run the current line and display the results
- `K`: Describe the table name at the current cursor location

It also creates the `cp` operator, which does exactly what you'd expect given the above (so `cpip`
will run the current paragraph, etc.)
