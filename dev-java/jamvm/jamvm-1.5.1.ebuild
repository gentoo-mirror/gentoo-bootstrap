# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools eutils flag-o-matic multilib java-vm-2

DESCRIPTION="An extremely small and specification-compliant virtual machine."
HOMEPAGE="http://jamvm.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="bootstrap"
KEYWORDS="amd64"

CLASSPATH_SLOT="bootstrap"
DEPEND="dev-java/gnu-classpath:${CLASSPATH_SLOT}"

RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
}

src_prepare() {
	rm -v lib/classes.zip || die

	default
}

src_configure() {
	export JAVAC="${EPREFIX}/usr/bin/jikes-bin"
	epatch "${FILESDIR}/classes-location.patch"
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
}
