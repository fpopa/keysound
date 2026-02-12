.PHONY: sounds build run clean

sounds:
	python3 scripts/generate-sounds.py

build: sounds
	bash scripts/build.sh

run: build
	open build/KeySound.app

clean:
	rm -rf build .build
	rm -f Resources/keydown.wav Resources/keyup.wav
