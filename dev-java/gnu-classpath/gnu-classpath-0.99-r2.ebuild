# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils java-pkg-2 java-vm-2 multilib

MY_P=${P/gnu-/}
DESCRIPTION="Free core class libraries for use with VMs and compilers for the Java language"
SRC_URI="mirror://gnu/classpath/${MY_P}.tar.gz"
HOMEPAGE="https://www.gnu.org/software/classpath"

LICENSE="GPL-2-with-linking-exception"
SLOT="0.99"
KEYWORDS="amd64 arm64"

IUSE=""
REQUIRED_USE=""

DEPEND="app-arch/zip
		dev-java/eclipse-ecj:3.2
		>=dev-java/java-config-2.1.11
		dev-java/jamvm:1.5"

RDEPEND="${DEPEND}
	virtual/jre:1.4"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	JAVA_PKG_WANT_BUILD_VM="jamvm-1.5"
	JAVA_PKG_WANT_SOURCE="1.5"
	JAVA_PKG_WANT_TARGET="1.5"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup
}

src_prepare() {
	eapply_user
	eapply "${FILESDIR}/classpath-aarch64-support.patch"
}

src_configure() {
	local ecj_pkg="eclipse-ecj"

	# We require ecj anyway, so force it to avoid problems with bad versions of javac
	export JAVAC="${EPREFIX}/usr/bin/ecj-3.2"
	# build takes care of them itself, duplicate -source -target kills ecj
	export JAVACFLAGS="-nowarn"
	# build system is passing -J-Xmx768M which ecj however ignores
	# this will make the ecj launcher do it (seen case where default was not enough heap)
	export gjl_java_args="-Xmx768M"
	export CLASSPATH=/usr/share/classpath/glibj.zip

	ANTLR= econf \
		--disable-Werror \
		--disable-gmp \
		--disable-gtk-peer \
		--disable-gconf-peer \
		--disable-dssi \
		--disable-alsa \
		--disable-gjdoc \
		--enable-jni \
		--disable-dependency-tracking \
		--disable-plugin \
		--disable-examples \
		--prefix="${EPREFIX}/usr/$(get_libdir)/classpath-0.99" \
		--with-glibj-dir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99/share/classpath" \
		--datadir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99" \
		--datarootdir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99/share" \
		--mandir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99/share/man" \
		--infodir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99/share/info" \
		--with-ecj-jar=$(java-pkg_getjar --build-only ${ecj_pkg}-* ecj.jar)
}

src_compile() {
	emake DESTDIR="${D}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS BUGS ChangeLog* HACKING NEWS README THANKYOU TODO
	java-pkg_regjar "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99/share/classpath/glibj.zip
	java-pkg_regjar "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99/classpath/tools.zip
	dosym "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99/bin/gjavah "${EPREFIX}"/usr/bin/gjavah
}
