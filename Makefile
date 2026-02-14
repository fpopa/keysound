.PHONY: sounds build run ship dmg clean

sounds:
	bash scripts/prepare-sounds.sh

build: sounds
	bash scripts/build.sh

run: build
	open build/KeySound.app

ship: sounds
	ENABLE_DEBUG_FEATURES=0 bash scripts/build.sh

dmg: ship
	bash scripts/create-dmg.sh

clean:
	rm -rf build .build
	rm -rf Resources/sounds
