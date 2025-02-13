VERSION="JamVM ${PV}"
JAVA_HOME="${EPREFIX}/usr/${PN}"
BOOTCLASSPATH="${EPREFIX}/usr/share/${PN}/classes.zip:${EPREFIX}/usr/share/classpath/glibj.zip"
JDK_HOME="${EPREFIX}/usr/${PN}"
JAVAC="\${JAVA_HOME}/bin/javac"
PATH="\${JAVA_HOME}/bin"
ROOTPATH="\${JAVA_HOME}/bin"
PROVIDES_TYPE="JDK JRE"
PROVIDES_VERSION="1.4"
GENERATION="2"
LDPATH="${EPREFIX}/usr/${PN}/$(get_libdir):${EPREFIX}/usr/$(get_libdir)/classpath"
ENV_VARS="JAVA_HOME JDK_HOME JAVAC PATH LDPATH"
