ARG ubuntu_version


FROM ubuntu:${ubuntu_version} AS build
ARG pacman_version
WORKDIR /tmp

RUN : \
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
	libarchive-tools \
	libcurl4-openssl-dev \
	libgpgme-dev \
	libssl-dev \
	m4 \
	meson \
	patchutils \
	pkg-config \
	python3-setuptools \
	xsltproc \
	xz-utils \
&& rm -Rf /var/{cache/apt,lib/apt/lists,log/{alternatives.log,apt,dpkg.log}} \
;

RUN : \
&& gpg --update-trustdb \
&& gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD \
&& echo '5\ny\n' | gpg --command-fd 0 --no-tty --edit-key 6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD trust \
&& gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys B8151B117037781095514CA7BBDFFC92306B1121 \
&& echo '5\ny\n' | gpg --command-fd 0 --no-tty --edit-key B8151B117037781095514CA7BBDFFC92306B1121 trust \
&& gpg --update-trustdb \
;

RUN : \
&& curl -sLO https://gitlab.archlinux.org/pacman/pacman/-/releases/v${pacman_version}/downloads/pacman-${pacman_version}.tar.xz \
&& curl -sLO https://gitlab.archlinux.org/pacman/pacman/-/releases/v${pacman_version}/downloads/pacman-${pacman_version}.tar.xz.sig \
&& gpg --verify --status-fd 1 pacman-${pacman_version}.tar.xz.sig pacman-${pacman_version}.tar.xz | grep -qE '^\[GNUPG:\] TRUST_(FULLY|ULTIMATE).*$' \
&& tar -xf pacman-${pacman_version}.tar.xz \
&& rm pacman-${pacman_version}.tar.xz pacman-${pacman_version}.tar.xz.sig \
;

COPY *.patch ./
RUN : \
&& cd pacman-${pacman_version}/ \
&& for patch in ../*.patch; do patch -p1 -i "${patch}"; done \
&& rm ../*.patch \
;

RUN : \
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
;


FROM ubuntu:${ubuntu_version}
RUN : \
&& apt update \
&& env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
	gnupg \
	libarchive13 \
	libarchive-tools \
	libcurl4 \
	libgpgme11 \
	libssl3 \
	zstd \
&& rm -Rf /var/{cache/apt,lib/apt/lists,log/{alternatives.log,apt,dpkg.log}} \
;
COPY --from=build /tmp/install /
RUN : \
&& ldconfig \
&& { pacman || true; } \
;
