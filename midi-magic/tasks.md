- pyinvoke
  - Works pretty well in practice. Has a lot of things I look for in
    make as a task runner: echoing of commands, dry run, shell syntax, running
    tasks by name, task dependencies (though not file). It lacks the ability to
    pass a list to run() (issue open since 2012) so we must manually quote args,
    which is error-prone and ugly. Maintenance has fallen off as of 2020 and
    there are a large number of outstanding pull requests and issues. 
- [pynt](https://github.com/rags/pynt)
  - Haven't tried, but looks like just the task portion of pyinvoke. Would
    need to combine with other modules such as sh or plumbum for running
    commands, and implement dry-run/echo yourself. Cmdline arg passing is ugly.
- plumbum (as a command runner) 
  - Odd syntax for python but actually works well.
    Avoids the quoting issues of pyinvoke, while allowing easy redirection and
    piping. Seems efficient for pipes, as it connects them instead of reading in
    all output -- unlike every other python command runner. When redirects or
    pipes are involved there are an excessive amount of parentheses just 
    due to operator precedence. For example, `((a < b) > c)()` or `(a[b] | c[d])()`
    or `(a | b) & FG`.
