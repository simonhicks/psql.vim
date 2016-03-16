# PSQL.vim

This is a plugin to let you send SQL statements from vim to psql and get the results back in a vim
buffer. It's very basic, and so far has the following limitations:

- Only supports passwordless DB login
- Only supports submitting the entire buffer content to psql at once

There are probably more limitations too. I basically wrote this specifically so I could poke around
a specific DB server from vim, so I really only *know* that it works on that server.
