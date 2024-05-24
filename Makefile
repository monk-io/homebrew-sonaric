.PHONY: sha
sha:
	shasum -a 256 sonaric-entrypoint.sh
	shasum -a 256 sonaric-runtime.sh
