# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils java-pkg-2 java-vm-2 multilib git-r3

DESCRIPTION="Free core class libraries for use with VMs and compilers for the Java language"
EGIT_REPO_URI="https://git.savannah.gnu.org/git/classpath.git"
EGIT_COMMIT="e7c13ee0cf2005206fbec0eca677f8cf66d5a103"
HOMEPAGE="https://www.gnu.org/software/classpath"

LICENSE="GPL-2-with-linking-exception"
SLOT="0.99-devel"
KEYWORDS="amd64 arm64"

IUSE=""
REQUIRED_USE=""

RDEPEND=""

DEPEND="app-arch/zip
		dev-java/eclipse-ecj:3.2
		>=dev-java/java-config-2.1.11
		virtual/jdk:1.5
		${RDEPEND}"

RDEPEND="${DEPEND}
	virtual/jre:1.5"

S=${WORKDIR}/${P}

pkg_setup() {
	JAVA_PKG_WANT_BUILD_VM="jamvm-2.0"
	JAVA_PKG_WANT_SOURCE="1.5"
	JAVA_PKG_WANT_TARGET="1.5"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup
}

src_prepare() {
	eapply_user
	eapply "${FILESDIR}/classpath-aarch64-support.patch"

	sh autogen.sh

	find . -name '*.java' -exec sed -i -e 's/@Override//g' {} \;
}

src_configure() {
	local ecj_pkg="eclipse-ecj"

	# build takes care of them itself, duplicate -source -target kills ecj
	export JAVACFLAGS="-nowarn"
	# build system is passing -J-Xmx768M which ecj however ignores
	# this will make the ecj launcher do it (seen case where default was not enough heap)
	export gjl_java_args="-Xmx768M"
	export LD_LIBRARY_PATH=/usr/$(get_libdir)/classpath

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
		--prefix="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel" \
		--with-glibj-dir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel/share/classpath" \
		--datadir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel" \
		--datarootdir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel/share" \
		--with-ecj-jar=$(java-pkg_getjar --build-only ${ecj_pkg}-* ecj.jar)
}

src_compile() {
	emake DESTDIR="${D}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS BUGS ChangeLog* HACKING NEWS README THANKYOU TODO
	java-pkg_regjar "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99-devel/share/classpath/glibj.zip
	java-pkg_regjar "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99-devel/classpath/tools.zip
	dosym "${EPREFIX}"/usr/$(get_libdir)/classpath-0.99-devel/bin/gjavah "${EPREFIX}"/usr/bin/gjavah-devel
}
