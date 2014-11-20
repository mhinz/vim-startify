test: test/vader.vim
	cd test && ./run

# Use existing vader install from ~/.vim, or clone it.
test/vader.vim:
	existing_vader=$(firstword $(wildcard ~/.vim/*bundle*/vader*)); \
	if [ -n "$$existing_vader" ]; then \
		( cd test && ln -s $$existing_vader vader.vim ); \
	else \
		git https://github.com/junegunn/vader.vim test/vader.vim; \
	fi

.PHONY: test
