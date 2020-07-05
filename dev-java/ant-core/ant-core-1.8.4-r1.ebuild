# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# don't depend on itself
JAVA_ANT_DISABLE_ANT_CORE_DEP=true
# rewriting build.xml files for the testcases has no reason atm
JAVA_PKG_BSFIX_ALL=no
inherit eutils java-pkg-2 java-vm-2 java-ant-2

MY_P="apache-ant-${PV}"

DESCRIPTION="Java-based build tool similar to 'make' that uses XML configuration files"
HOMEPAGE="http://ant.apache.org/"
SRC_URI="http://archive.apache.org/dist/ant/source/apache-ant-${PV}-src.tar.bz2"

LICENSE="Apache-2.0"
SLOT="bootstrap"
KEYWORDS="amd64 arm64"
IUSE="doc"

RDEPEND="dev-java/jamvm:1.5
	!dev-java/ant-core:0"
DEPEND="${RDEPEND}"


S="${WORKDIR}/${MY_P}"

src_prepare() {
	sed -i -e 's/depends="jars,test-jar"/depends="jars"/' build.xml || die "Sed failed!"

	default
}

pkg_setup() {
	JAVA_PKG_WANT_BUILD_VM="jamvm-1.5"
	JAVA_PKG_WANT_SOURCE="1.4"
	JAVA_PKG_WANT_TARGET="1.4"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup
}

src_compile() {
	export BOOTJAVAC_OPTS="-nowarn"
	export ANT_OPTS="-Dbuild.compiler=jikes"

	./build.sh || die "build failed"
}

src_install() {
	dodir /usr/share/ant/lib
	for jar in ant.jar ant-bootstrap.jar ant-launcher.jar ; do
		java-pkg_dojar build/lib/${jar}
		dosym /usr/share/${PN}-bootstrap/lib/${jar} /usr/share/ant/lib/${jar}
	done

	dobin "${S}/dist/bin/ant" || die "failed to install wrapper"
	dodir /usr/share/${PN}/bin
	for each in antRun antRun.pl runant.pl runant.py complete-ant-cmd.pl ; do
		dobin "${S}/src/script/${each}"
		dosym /usr/bin/${each} /usr/share/${PN}/bin/${each}
	done
	dosym /usr/share/${PN}/bin /usr/share/ant/bin

	insinto /usr/share/${PN}

	echo "ANT_HOME=\"${EPREFIX}/usr/share/ant\"" > "${T}/20ant"
	doenvd "${T}/20ant" || die "failed to install env.d file"

	dodoc NOTICE README WHATSNEW KEYS || die
}
