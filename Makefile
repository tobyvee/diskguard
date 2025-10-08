.PHONY: test install-bats

test: install-bats 
	sudo bats -p --verbose-run diskguard_test.bats 

install-bats:
	@which bats > /dev/null || (echo "Installing bats..." && brew install bats-core)