# Cleaning Up barf's Structure

2023-10-09

Things probably look a little different around here. Both in terms of this demo site *and* the core `barf` files itself.

This project was always intended to be focused on Linux platforms. So, I've removed the included `barf_macos` and `barf_openbsd` files to keep the generator more streamlined. But have no fear! Instructions for both Mac and OpenBSD can still be found on the main blog:

- [Running `barf` on MacOS](/macos)
- [Running `barf` on OpenBSD](/openbsd)

As for the "default" look of `barf`, I've simplified things further. The total CSS styling now consists of only:

```
*{box-sizing:border-box;}
body{font-family:sans-serif;margin:0 auto;max-width:650px;padding:1rem;}
img{max-width:100%;}
pre{overflow:auto;}
```

Users still have the ability to tweak things as much as they'd like, but the standard look should be more than enough for anyone just focusing on writing. Dark mode has also been dropped but is easily added by adding the following inside the `head` tags:

```
<meta name="color-scheme" content="dark light">
```

Hopefully these changes reduce the overall scope of the project, which was a main point made on the README originally!