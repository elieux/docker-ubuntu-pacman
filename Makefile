pacman_version:=5.2.2

.PHONY: image
image: Dockerfile *.patch
	docker build . --build-arg pacman_version=$(pacman_version) -t elieux/ubuntu-pacman:$(pacman_version)-ubuntu20.04

.PHONY: upload
upload:
	docker push elieux/ubuntu-pacman:$(pacman_version)-ubuntu20.04
