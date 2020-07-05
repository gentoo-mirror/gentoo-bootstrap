# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="${PV}"
KEYWORDS="amd64 arm64"

RDEPEND="dev-java/jamvm:2.0-3
         dev-java/eclipse-ecj:4.2
         dev-java/gnu-classpath:0.99-devel"
