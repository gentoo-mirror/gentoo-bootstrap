# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils java-pkg-2 multilib

MY_P=${P/gnu-/}
DESCRIPTION="Free core class libraries for use with VMs and compilers for the Java language"
SRC_URI="mirror://gnu/classpath/${MY_P}.tar.gz"
HOMEPAGE="https://www.gnu.org/software/classpath"

LICENSE="GPL-2-with-linking-exception"
SLOT="0.93"
KEYWORDS="amd64 arm64"

DEPEND="sys-libs/zlib
		app-arch/fastjar
		dev-java/java-config
		dev-java/jikes
		dev-libs/libltdl
		${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_prepare() {
	eapply "${FILESDIR}/classpath-aarch64-support.patch"
	eapply "${FILESDIR}/classpath-miscompilation.patch"
	eapply_user
}

src_configure() {
	export JAVAC="${EPREFIX}/usr/bin/jikes"
	export BOOTCLASSPATH="none"
	econf \
		--disable-Werror \
		--disable-gmp \
		--disable-gtk-peer \
		--disable-gconf-peer \
		--disable-plugin \
		--disable-dssi \
		--disable-alsa \
		--disable-gjdoc \
		--bindir="${EPREFIX}"/usr/libexec/${PN} \
		--with-glibj-dir="${EPREFIX}"/usr/share/classpath \
		--includedir="${EPREFIX}"/usr/include/classpath
}

src_compile() {
	emake DESTDIR="${D}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS BUGS ChangeLog* HACKING NEWS README THANKYOU TODO
}
