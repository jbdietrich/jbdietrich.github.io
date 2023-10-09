# Running `barf` on OpenBSD

2023-08-12

The `barf` project was built on Linux and was catered towards Linux users. The core of the project will remain focused on Linux/GNU tools, but I also need to support OpenBSD since that is my personal operating system of choice.

## Download Packages

Along with your Markdown parser of choice (`barf` assumes you will be using my version of [smu](https://git.sr.ht/~bt/smu)) you will also need to install the required packages on your OpenBSD system:

```
doas pkg_add rsync coreutils gsed cmake gcc
```

Then ensure that you alter all instances of `sed` with `gsed` in the core `barf` file. (Or make an alias if you'd prefer not to alter the main file)

After that, everything should work perfectly fine when building!
