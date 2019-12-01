# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils flag-o-matic multilib java-vm-2 autotools

DESCRIPTION="An extremely small and specification-compliant virtual machine"
HOMEPAGE="http://jamvm.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="bootstrap"
KEYWORDS="amd64"
IUSE="libffi"

DEPEND="dev-java/gnu-classpath:bootstrap
	dev-java/eclipse-ecj:4.2
	libffi? ( virtual/libffi )
	ppc64? ( virtual/libffi )
	sparc? ( virtual/libffi )"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/"${P}-classes-location.patch"
	"${FILESDIR}"/"${P}-noexecstack.patch"
)

src_prepare() {
	# without this patch, classes.zip is not found at runtime
	epatch "${PATCHES[@]}"

	sed -i -e "s/return CLASSPATH_INSTALL_DIR\"\/lib\/classpath\";/return CLASSPATH_INSTALL_DIR\"\/$(get_libdir)\/classpath\";/g" src/classlib/gnuclasspath/dll.c || die "Sed failed!"

	eautoreconf

	# These come precompiled.
	# configure script uses detects the compiler
	# from PATH. I guess we should compile this from source.
	# Then just make sure not to hit
	# https://bugs.gentoo.org/show_bug.cgi?id=163801
	#
	rm -v src/classlib/gnuclasspath/lib/classes.zip || die
}

src_configure() {
	export CLASSPATH=/usr/share/classpath/glibj.zip

	filter-flags "-fomit-frame-pointer"

	if use ppc64 || use sparc || use libffi; then
		append-cflags "$(pkg-config --cflags-only-I libffi)"
	fi

	local fficonf="--enable-ffi"
	if { ! use ppc64 && ! use sparc; }; then
		fficonf="$(use_enable libffi ffi)"
	fi

	econf ${fficonf} \
		--disable-dependency-tracking \
		--libdir="${EPREFIX}"/usr/$(get_libdir)/${PN} \
		--includedir="${EPREFIX}"/usr/include/${PN} \
		--with-classpath-install-dir="${EPREFIX}/usr"
}

src_compile() {
	export LD_LIBRARY_PATH="${EPREFIX}/usr/$(get_libdir)/classpath"
	default
}

create_launcher() {
	local script="${D}/${INSTALL_DIR}/bin/${1}"
	cat > "${script}" <<-EOF
		#!/bin/sh
		exec /usr/bin/jamvm \
			-Xbootclasspath/p:/usr/share/classpath/tools.zip" \
			gnu.classpath.tools.${1}.Main "\$@"
	EOF
	chmod +x "${script}" || die
}

src_install() {
	local libdir=$(get_libdir)
	local CLASSPATH_DIR=/usr/libexec/gnu-classpath
	local JDK_DIR=/usr/${libdir}/${PN}-jdk

	emake DESTDIR="${D}" install

	dodoc ACKNOWLEDGEMENTS AUTHORS ChangeLog NEWS README

	set_java_env "${FILESDIR}/${P}-env.file"

	dodir ${JDK_DIR}/bin
	dosym /usr/bin/jamvm ${JDK_DIR}/bin/java
	for files in ${CLASSPATH_DIR}/g*; do
		if [ $files = "${CLASSPATH_DIR}/bin/gjdoc" ] ; then
			dosym $files ${JDK_DIR}/bin/javadoc || die
		else
			dosym $files \
				${JDK_DIR}/bin/$(echo $files|sed "s#$(dirname $files)/g##") || die
		fi
	done

	dodir ${JDK_DIR}/jre/lib
	dosym /usr/share/classpath/glibj.zip ${JDK_DIR}/jre/lib/rt.jar
	dodir ${JDK_DIR}/lib
	dosym "${EPREFIX}/usr/share/classpath/tools.zip" ${JDK_DIR}/lib/tools.jar
	dosym "${EPREFIX}/usr/include/classpath" ${JDK_DIR}/include

	local ecj_jar="$(readlink "${EPREFIX}"/usr/share/eclipse-ecj/ecj.jar)"
	exeinto ${JDK_DIR}/bin
	sed -e "s#@JAVA@#/usr/bin/jamvm#" \
		-e "s#@ECJ_JAR@#${ecj_jar}#" \
		-e "s#@RT_JAR@#/usr/share/classpath/glibj.zip#" \
		-e "s#@TOOLS_JAR@#/usr/share/classpath/tools.zip#" \
		"${FILESDIR}"/"${P}-javac.in" | newexe - javac

	local libarch="${ARCH}"
	[ ${ARCH} == x86 ] && libarch="i386"
	[ ${ARCH} == x86_64 ] && libarch="amd64"
	dodir ${JDK_DIR}/jre/lib/${libarch}/client
	dodir ${JDK_DIR}/jre/lib/${libarch}/server
	dosym /usr/${libdir}/${PN}/libjvm.so ${JDK_DIR}/jre/lib/${libarch}/client/libjvm.so
	dosym /usr/${libdir}/${PN}/libjvm.so ${JDK_DIR}/jre/lib/${libarch}/server/libjvm.so

	# Can't use java-vm_set-pax-markings as doesn't work with symbolic links
	# Ensure a PaX header is created.
	local pax_markings="C"
	# Usually disabling MPROTECT is sufficient.
	local pax_markings+="m"
	# On x86 for heap sizes over 700MB disable SEGMEXEC and PAGEEXEC as well.
	use x86 && pax_markings+="sp"

	pax-mark ${pax_markings} "${ED}"/usr/bin/jamvm
}
