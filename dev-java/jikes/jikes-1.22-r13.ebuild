# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic eutils

DESCRIPTION="IBM's open source, high performance Java compiler"
HOMEPAGE="http://jikes.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
LICENSE="IBM"
SLOT="0"
KEYWORDS="amd64 arm64"
RDEPEND=">=dev-java/java-config-2.0.0"

src_unpack() {
	unpack ${A}
	cd "${S}"
}

src_configure() {
	eapply -p0 "${FILESDIR}"/deprecated.patch
	econf || die "configure problem"

	default
}

src_compile() {
	filter-flags "-fno-rtti"
	emake || die "compile problem"
}

src_install () {
	make DESTDIR="${D}" install || die "install problem"

	mv "${D}"/usr/bin/jikes{,-bin}
	dobin "${FILESDIR}"/jikes

	insinto /usr/share/java-config-2/compiler
	newins "${FILESDIR}"/compiler-settings jikes
}
