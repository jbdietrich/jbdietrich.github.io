build:
	rm -rf build && mkdir build
	ruby blog.rb

clean:
	rm -rf build/*

.PHONY: build clean
