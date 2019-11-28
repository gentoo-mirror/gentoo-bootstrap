# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Java Runtime Environment (JRE)"
SLOT="${PV}"
KEYWORDS="amd64"

RDEPEND="
	virtual/jdk:${SLOT}
	>=dev-java/gnu-classpath-0.99_p1
	>=dev-java/jamvm-2.0.0-r99:bootstrap
"
