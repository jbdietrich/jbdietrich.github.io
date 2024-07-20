# wruby

> This is a heavy work-in-progress. Consider this in alpha state.

Minimal blog and static site generator. The "w" is silent...

## Dependencies

- `ruby`

Install required gems:

```
gem install kramdown rss
```

## Running

1. Create markdown blog posts under root `posts/` directory
2. Create markdown pages under root `/pages` directory
3. Store media (images, videos etc) inside the root `/public` directory
4. Run `make build` in root
5. Upload `build` folder to your server