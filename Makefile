build:
	rm -rf build && mkdir build
	bundle exec ruby wruby.rb 

clean:
	rm -rf build/*

.PHONY: build clean
