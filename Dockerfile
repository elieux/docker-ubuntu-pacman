FROM ubuntu:20.04 AS build
ARG pacman_version
WORKDIR /tmp

RUN true \
&& apt update \
&& env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
	asciidoc \
	ca-certificates \
	curl \
	docbook-xml \
	docbook-xsl \
	g++ \
	gnupg \
	libarchive-dev \
	libcurl4-openssl-dev \
	libgpgme-dev \
	libssl-dev \
	m4 \
	meson \
	patchutils \
	pkg-config \
	python3-setuptools \
	xsltproc \
&& rm -Rf /var/{cache/apt,lib/apt/lists,log/{alternatives.log,apt,dpkg.log}} \
&& true

RUN true \
&& gpg --update-trustdb \
&& gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD \
&& echo '5\ny\n' | gpg --command-fd 0 --no-tty --edit-key 6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD trust \
&& gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys B8151B117037781095514CA7BBDFFC92306B1121 \
&& echo '5\ny\n' | gpg --command-fd 0 --no-tty --edit-key B8151B117037781095514CA7BBDFFC92306B1121 trust \
&& gpg --update-trustdb \
&& true

RUN true \
&& curl -sLO https://sources.archlinux.org/other/pacman/pacman-${pacman_version}.tar.gz \
&& curl -sLO https://sources.archlinux.org/other/pacman/pacman-${pacman_version}.tar.gz.sig \
&& gpg --verify --status-fd 1 pacman-${pacman_version}.tar.gz.sig pacman-${pacman_version}.tar.gz | grep -qE '^\[GNUPG:\] TRUST_(FULLY|ULTIMATE).*$' \
&& tar -xzf pacman-${pacman_version}.tar.gz \
&& rm pacman-${pacman_version}.tar.gz pacman-${pacman_version}.tar.gz.sig \
&& true

COPY *.patch ./
RUN true \
&& cd pacman-${pacman_version}/ \
&& for patch in ../*.patch; do patch -p1 -i "${patch}"; done \
&& rm ../*.patch \
&& true

RUN true \
&& { \
	env PATH=/sbin:/bin meson setup build/ pacman-${pacman_version}/ \
		--buildtype=release \
		--prefix=/usr/local \
		--libdir=lib \
		-Duse-git-version=false \
	|| cat build/meson-logs/meson-log.txt >&2; \
} \
&& ninja -C build/ \
&& env DESTDIR=/tmp/install meson install -C build/ \
&& true


FROM ubuntu:20.04
RUN true \
&& apt update \
&& env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
	gnupg \
	libarchive13 \
	libarchive-tools \
	libcurl4 \
	libgpgme11 \
	libssl1.1 \
&& rm -Rf /var/{cache/apt,lib/apt/lists,log/{alternatives.log,apt,dpkg.log}} \
&& true
COPY --from=build /tmp/install /
RUN true \
&& ldconfig \
&& { pacman || true; } \
&& true
