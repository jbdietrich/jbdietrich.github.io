# wruby

> This is a heavy work-in-progress and I am hardly a Ruby expert.
>
> Please consider contributing to make the project better!

Minimal blog and static site generator. The "w" is silent...

## Dependencies

- `ruby`

Install required gems:

```
gem install kramdown rss
```

## Getting Started

Make your changes in the top of the main `wruby.rb` file (site URL, your name,
etc.). Remove the `.build.yml` unless you plan to host with sourcehut pages,
otherwise edit this file with your own details.

* Blog posts go under the `posts` directory as markdown files
  - Posts need to be structured with an `h1` on the first line, a space on the
    second, and the date on the third line (ie. 2024-07-20)
* Pages go under the `pages` directory as markdown files
* Media (images, videos etc) go in the root `public` directory

## Running

1. Run `make build` in the root directory
2. Upload `build` folder to your server
3. Share your blog or site!
