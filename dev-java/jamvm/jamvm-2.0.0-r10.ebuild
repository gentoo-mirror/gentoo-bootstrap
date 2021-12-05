# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils flag-o-matic multilib java-pkg-2 java-vm-2 autotools

DESCRIPTION="An extremely small and specification-compliant virtual machine"
HOMEPAGE="http://jamvm.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="2.0-2"
KEYWORDS="amd64 arm64"
IUSE="libffi"

DEPEND="dev-java/gnu-classpath:0.99-devel
	dev-java/eclipse-ecj:3.2
	libffi? ( virtual/libffi )
	ppc64? ( virtual/libffi )
	sparc? ( virtual/libffi )"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-2-classes-location.patch"
	"${FILESDIR}/${P}-noexecstack.patch"
	"${FILESDIR}/${P}-aarch64-support.patch"
	"${FILESDIR}/${P}-opcode-guard.patch"
)

src_prepare() {
	eapply_user
	# without this patch, classes-2.zip is not found at runtime
	eapply "${PATCHES[@]}"

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

pkg_setup() {
	JAVA_PKG_WANT_BUILD_VM="jamvm-2.0"
	JAVA_PKG_WANT_SOURCE="1.5"
	JAVA_PKG_WANT_TARGET="1.5"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup
}

src_configure() {
	export CLASSPATH="${EPREFIX}"/usr/$(get_libdir)/classpath-0.99-devel/share/classpath/glibj.zip

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
		--libdir="${EPREFIX}"/usr/$(get_libdir)/${PN}-jdk2 \
		--datadir="${EPREFIX}"/usr/share \
		--bindir="${EPREFIX}"/usr/bin \
		--includedir="${EPREFIX}"/usr/include/${PN}2 \
		--with-classpath-install-dir="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel"
}

src_compile() {
	export LD_LIBRARY_PATH="${EPREFIX}/usr/$(get_libdir)/classpath-0.99-devel/$(get_libdir)"
	default
}

src_install() {
	local libdir=$(get_libdir)
	local CLASSPATH_DIR="${EPREFIX}"/usr/${libdir}/classpath-0.99-devel/bin
	local JDK_DIR="${EPREFIX}"/usr/${libdir}/${PN}-jdk2

	emake DESTDIR="${D}" install

	dodoc ACKNOWLEDGEMENTS AUTHORS ChangeLog NEWS README

	set_java_env "${FILESDIR}/${P}-2-env.file"

	dodir ${JDK_DIR}/bin
	mv "${ED}"usr/bin/jamvm "${ED}"usr/bin/jamvm-2.0-2
	mv "${ED}"usr/share/jamvm/classes.zip "${ED}"usr/share/jamvm/classes-2.zip
	dosym "${EPREFIX}"/usr/bin/jamvm-2.0-2 ${JDK_DIR}/bin/java
	for files in ${CLASSPATH_DIR}/g*; do
		if [ $files = "${CLASSPATH_DIR}/bin/gjdoc" ] ; then
			dosym $files ${JDK_DIR}/bin/javadoc || die
		else
			dosym $files \
				${JDK_DIR}/bin/$(echo $files|sed "s#$(dirname $files)/g##") || die
		fi
	done

	dodir ${JDK_DIR}/jre/lib
	dosym "${EPREFIX}"/usr/${libdir}/classpath-0.99-devel/share/classpath/glibj.zip ${JDK_DIR}/jre/lib/rt.jar
	dodir ${JDK_DIR}/lib
	dosym "${EPREFIX}"/usr/${libdir}/classpath-0.99-devel/classpath/tools.zip ${JDK_DIR}/lib/tools.jar
	dosym "${EPREFIX}/usr/${libdir}/classpath-0.99-devel/include/" ${JDK_DIR}/include

	local ecj_jar="${EPREFIX}"/usr/share/eclipse-ecj-3.2/lib/ecj.jar
	exeinto ${JDK_DIR}/bin
	sed -e "s#@JAVA@#/usr/bin/jamvm-2.0-2#" \
		-e "s#@ECJ_JAR@#${ecj_jar}#" \
		-e "s#@RT_JAR@#/usr/${libdir}/jamvm-jdk2/jre/lib/rt.jar#" \
		-e "s#@TOOLS_JAR@#/usr/${libdir}/jamvm-jdk2/lib/tools.jar#" \
		"${FILESDIR}"/"${P}-javac.in" | newexe - javac

	local libarch="${ARCH}"
	[ ${ARCH} == x86 ] && libarch="i386"
	[ ${ARCH} == x86_64 ] && libarch="amd64"
	dodir ${JDK_DIR}/jre/lib/${libarch}/client
	dodir ${JDK_DIR}/jre/lib/${libarch}/server

	# Can't use java-vm_set-pax-markings as doesn't work with symbolic links
	# Ensure a PaX header is created.
	local pax_markings="C"
	# Usually disabling MPROTECT is sufficient.
	local pax_markings+="m"
	# On x86 for heap sizes over 700MB disable SEGMEXEC and PAGEEXEC as well.
	use x86 && pax_markings+="sp"

	pax-mark ${pax_markings} "${ED}"/usr/bin/jamvm-2.0-2
}
