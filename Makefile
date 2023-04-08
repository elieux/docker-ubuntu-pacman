ubuntu_version:=22.04
pacman_version:=6.0.2
tag:=elieux/ubuntu-pacman:$(pacman_version)-ubuntu$(ubuntu_version)

.PHONY: image
image: Dockerfile *.patch
	docker build . \
		--pull \
		--build-arg ubuntu_version=$(ubuntu_version) \
		--build-arg pacman_version=$(pacman_version) \
		-t $(tag)

.PHONY: upload
upload:
	docker push $(tag)
