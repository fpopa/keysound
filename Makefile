.PHONY: sounds build run clean

sounds:
	bash scripts/prepare-sounds.sh

build: sounds
	bash scripts/build.sh

run: build
	open build/KeySound.app

clean:
	rm -rf build .build
	rm -rf Resources/sounds
