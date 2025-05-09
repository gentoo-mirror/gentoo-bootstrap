# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

VERSION="JamVM JDK ${PV}"
JAVA_HOME="${EPREFIX}/usr/$(get_libdir)/${PN}-jdk3"
JDK_HOME="${EPREFIX}/usr/$(get_libdir)/${PN}-jdk3"
BOOTCLASSPATH="${EPREFIX}/usr/share/${PN}/classes-3.zip:${JAVA_HOME}/jre/lib/rt.jar"
JAVAC="\${JAVA_HOME}/bin/javac"
PATH="\${JAVA_HOME}/bin"
ROOTPATH="\${JAVA_HOME}/bin"
PROVIDES_TYPE="JRE"
PROVIDES_VERSION="1.5"
GENERATION="2"
ENV_VARS="JAVA_HOME JAVAC PATH"
LDPATH="\${JAVA_HOME}/lib"
