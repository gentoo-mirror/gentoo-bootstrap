# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils java-pkg-2 multilib

MY_P=${P/gnu-/}
DESCRIPTION="Free core class libraries for use with VMs and compilers for the Java language"
SRC_URI="mirror://gnu/classpath/${MY_P}.tar.gz"
HOMEPAGE="https://www.gnu.org/software/classpath"

LICENSE="GPL-2-with-linking-exception"
SLOT="bootstrap"
KEYWORDS="amd64"

IUSE=""
REQUIRED_USE=""

RDEPEND=""

# java-config >2.1.11 needed for ecj version globbing
DEPEND="app-arch/zip
		dev-java/eclipse-ecj:3.2
		>=dev-java/java-config-2.1.11
		virtual/jdk:1.4
		${RDEPEND}"

RDEPEND="virtual/jre:1.4
	${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_configure() {
	local ecj_pkg="eclipse-ecj"

	# We require ecj anyway, so force it to avoid problems with bad versions of javac
	export JAVAC="${EPREFIX}/usr/bin/ecj-3.2"
	export JAVA="${EPREFIX}/usr/bin/java"
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
		--bindir="${EPREFIX}"/usr/libexec/${PN} \
		--includedir="${EPREFIX}"/usr/include/classpath \
		--with-ecj-jar=$(java-pkg_getjar --build-only ${ecj_pkg}-* ecj.jar)
}

src_compile() {
	emake DESTDIR="${D}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS BUGS ChangeLog* HACKING NEWS README THANKYOU TODO
	java-pkg_regjar /usr/share/classpath/glibj.zip
	java-pkg_regjar /usr/share/classpath/tools.zip
	dosym /usr/libexec/gnu-classpath/gjavah /usr/bin/gjavah
}
