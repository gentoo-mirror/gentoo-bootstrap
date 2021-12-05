# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools eutils flag-o-matic multilib java-vm-2

DESCRIPTION="An extremely small and specification-compliant virtual machine."
HOMEPAGE="http://jamvm.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.5"
KEYWORDS="amd64 arm64"

DEPEND="dev-java/gnu-classpath:0.93"

RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
}

src_prepare() {
	rm -v lib/classes.zip || die
	eapply "${FILESDIR}/classes-location.patch"
	eapply "${FILESDIR}/${P}-aarch64-support.patch"

	default
}

src_configure() {
	export JAVAC="${EPREFIX}/usr/bin/jikes-bin"
	sed -i -e "s/return CLASSPATH_INSTALL_DIR\"\/lib\/classpath\";/return CLASSPATH_INSTALL_DIR\"\/$(get_libdir)\/classpath\";/g" src/dll.c || die "Sed failed!"
	eautoreconf

	filter-flags "-fomit-frame-pointer"

	append-cflags "$(pkg-config --cflags-only-I libffi)"
	# Keep libjvm.so out of /usr
	# http://bugs.gentoo.org/show_bug.cgi?id=181896
	econf --enable-ffi \
		--disable-int-caching \
		--enable-runtime-reloc-checks \
		--prefix="${EPREFIX}"/usr/${PN} \
		--datadir="${EPREFIX}"/usr/share \
		--bindir="${EPREFIX}"/usr/bin \
		--with-classpath-install-dir="${EPREFIX}/usr" \
		|| die "configure failed."
}

src_compile() {
	emake || die "make failed."
}

src_install() {
	emake DESTDIR="${D}" install || die "installation failed."

	dodoc ACKNOWLEDGEMENTS AUTHORS ChangeLog NEWS README \
		|| die "dodoc failed"

	set_java_env "${FILESDIR}/${PN}-1.5.1.env"

	local bindir=/usr/${PN}/bin
	dodir ${bindir}
	dosym /usr/bin/jamvm ${bindir}/java
	dosym /usr/bin/jikes ${bindir}/javac
	dosym /usr/bin/fastjar ${bindir}/jar
}
