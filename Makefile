build:
	rm -rf docs && mkdir docs
	ruby wruby.rb

clean:
	rm -rf docs/*

.PHONY: build clean
