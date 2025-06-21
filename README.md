# wruby

* Minimal blog and static site generator
* Licensed under [MIT](https://choosealicense.com/licenses/mit/)
* Discussion, patches etc. go to the [list](https://lists.sr.ht/~bt/wruby-devel)
* The "w" is silent...

## Dependencies

* `ruby` (`ruby-dev` if needed)
* ruby gems: `kramdown` and `rss`

## Getting Started

Make your changes in the main configuration file `_config.yml` file (site URL, your name,
etc.).

* Blog posts go under the `posts` directory as markdown files
* Posts need to be structured with an `h1` on the first line, a space on the second, and the date on the third line (ie. 2024-07-20)
* Pages go under the `pages` directory as markdown files
* Media (images, videos etc) go in the root `public` directory
* Main styling is found in `public/style.css` (feel free to get creative!)

## Defaults

* The homepage only displays the first `5` posts. You can configure this in `_config.yml` under `post_count`.
* The full blog post index will be generated at `yoursite.com/posts`
* This means you need to have a `posts.md` file in your `pages` directory (or change `posts_index` the core `_config.yml`)

## Running

1. `wruby` is based off of Ruby 3.3.3 (use `rbenv` or `rvm` to avoid privilege conflicts)
2. Install dependencies: `gem install 'kramdown:2.4.0' 'rss:0.3.0'`
3. Run `make build` in the root directory
4. Upload `build` folder to your server
5. Share your blog or site!