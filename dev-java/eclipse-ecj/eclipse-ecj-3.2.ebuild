# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils java-pkg-2 java-ant-2

#MY_PN=${PN##*-}

DESCRIPTION="Eclipse Compiler for Java"
HOMEPAGE="http://www.eclipse.org/"
SRC_URI="${P}.tar.bz2"
LICENSE="EPL-1.0"
KEYWORDS="amd64"
SLOT="3.2"

RDEPEND=">=virtual/jre-1.4"

DEPEND="${RDEPEND}
	>=virtual/jdk-1.4
	dev-java/ant-core"

src_unpack() {
	unpack ${A}
	cd "${S}"
    
	# remove unzip, add javadoc target, put final ecj.jar and javadocs in dist/ and not ../
	epatch "${FILESDIR}/${P}-build-gentoo.patch"
}

src_compile() {
	# we don't use eant because the compile*.xml files specifically set -source -target and used compiler

	# bootstrap build with JDK's javac
	ant "-Dbuild.compiler=jikes" -f compilejdtcorewithjavac.xml || die "Failed to bootstrap build with javac"

	# recompile with ecj.jar made in first step, to get dist/ecj.jar
	export CLASSPATH=/usr/share/classpath/glibj.zip
	ant ${ant_flags} -lib ecj.jar -f compilejdtcore.xml compile $(use_doc) || die "Failed to rebuild with ecj"
}

src_install() {
	java-pkg_dojar dist/ecj.jar

	java-pkg_dolauncher ecj-${SLOT} --main org.eclipse.jdt.internal.compiler.batch.Main

	insinto /usr/share/java-config-2/compiler
	newins ${FILESDIR}/compiler-settings-${SLOT} ecj-${SLOT}
}

