# muncher

File appender service application.

## Run

To play around with app, just type:

```bash
$ rebar3 shell
```

in your shell, and try this:

```erlang
1> muncher:append("testfile", "string").
```

You should see similar output:

```
=INFO REPORT==== 15-Aug-2023::15:42:10.399401 ===
Open new file and append: cloak
ok
```

The file `testfile` will be appended with a string `string`, prepended by a newline. If the file
won't be appended **using the service API** for a **timeout** (*default*: 10 seconds), it will be
closed.  You can change the **timeout value** in the `src/muncher_sup.erl` file: just change `nil`
in the `ChildSpecs = [#{id => muncher_srv, start => {muncher_srv, start_link, [nil]}}],` line to
an integer value in seconds. You can append many files at a time.
