# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit check-reqs eapi7-ver flag-o-matic java-pkg-2 java-vm-2 multiprocessing pax-utils toolchain-funcs

MY_PV=${PV/_p/+}
SLOT=${MY_PV%%[.+]*}

BASE_URI="https://hg.${PN}.java.net/jdk-updates/jdk9u"

DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.java.net"
SRC_URI="
	${BASE_URI}/archive/jdk-${MY_PV}.tar.bz2 -> ${P}.tar.bz2
	${BASE_URI}/corba/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-corba-${PV}.tar.bz2
	${BASE_URI}/hotspot/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-hotspot-${PV}.tar.bz2
	${BASE_URI}/jaxp/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-jaxp-${PV}.tar.bz2
	${BASE_URI}/jaxws/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-jaxws-${PV}.tar.bz2
	${BASE_URI}/jdk/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-jdk-${PV}.tar.bz2
	${BASE_URI}/langtools/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-langtools-${PV}.tar.bz2
	${BASE_URI}/nashorn/archive/jdk-${MY_PV}.tar.bz2 -> ${PN}-nashorn-${PV}.tar.bz2
"

LICENSE="GPL-2"
KEYWORDS="amd64 arm64"
IUSE="alsa debug cups doc examples gentoo-vm headless-awt pch selinux source"

COMMON_DEPEND="
	media-libs/freetype:2=
	media-libs/giflib:0/7
	sys-libs/zlib
"
# Many libs are required to build, but not to run, make is possible to remove
# by listing conditionally in RDEPEND unconditionally in DEPEND
RDEPEND="
	${COMMON_DEPEND}
	>=sys-apps/baselayout-java-0.1.0-r1
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXt
		x11-libs/libXtst
	)
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
"

DEPEND="
	${COMMON_DEPEND}
	app-arch/zip
	media-libs/alsa-lib
	net-print/cups
	x11-base/xorg-proto
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	|| (
		dev-java/openjdk:${SLOT}
		dev-java/icedtea:${SLOT}
		dev-java/openjdk:$((SLOT-1))
		dev-java/icedtea:$((SLOT-1))
	)
"

S="${WORKDIR}/${PN}-${PV}"

# The space required to build varies wildly depending on USE flags,
# ranging from 2GB to 16GB. This function is certainly not exact but
# should be close enough to be useful.
openjdk_check_requirements() {
	local M
	M=2048
	M=$(( $(usex debug 3 1) * $M ))
	M=$(( $(usex doc 320 0) + $(usex source 128 0) + 192 + $M ))

	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}

pkg_pretend() {
	openjdk_check_requirements
	has ccache ${FEATURES} && die "FEATURES=ccache doesn't work with ${PN}"
}

pkg_setup() {
	openjdk_check_requirements
	java-vm-2_pkg_setup

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} icedtea-${SLOT} openjdk-$((SLOT-1)) icedtea-$((SLOT-1))"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	# The nastiness below is necessary while the gentoo-vm USE flag is
	# masked. First we call java-pkg-2_pkg_setup if it looks like the
	# flag was unmasked against one of the possible build VMs. If not,
	# we try finding one of them in their expected locations. This would
	# have been slightly less messy if openjdk-bin had been installed to
	# /opt/${PN}-${SLOT} or if there was a mechanism to install a VM env
	# file but disable it so that it would not normally be selectable.

	local vm
	for vm in ${JAVA_PKG_WANT_BUILD_VM}; do
		if [[ -d ${EPREFIX}/usr/lib/jvm/${vm} ]]; then
			java-pkg-2_pkg_setup
			return
		fi
	done

	if has_version --host-root dev-java/openjdk:${SLOT}; then
		export JDK_HOME=${EPREFIX}/usr/$(get_libdir)/openjdk-${SLOT}
	else
		if [[ ${MERGE_TYPE} != "binary" ]]; then
			JDK_HOME=$(best_version --host-root dev-java/openjdk-bin:${SLOT})
			[[ -n ${JDK_HOME} ]] || die "Build VM not found!"
			JDK_HOME=${JDK_HOME#*/}
			JDK_HOME=${EPREFIX}/opt/${JDK_HOME%-r*}
			export JDK_HOME
		fi
	fi
}

src_unpack() {
	default
	mv -v "jdk${SLOT}u"* "${P}" || die

	local repo
	for repo in corba hotspot jdk jaxp jaxws langtools nashorn; do
		mv -v "${repo}-"* "${P}/${repo}" || die
	done
}

src_prepare() {
	default

	# Delete pre-built files
	find . -name '*.jar' -type f -delete
	find . -name '*.bin' -type f -delete
	find . -name '*.exe' -type f -delete

	chmod +x configure || die

	# conditionally apply patches for musl compatibility
	if use elibc_musl; then
		eapply "${FILESDIR}/musl/${SLOT}/build.patch"
		eapply "${FILESDIR}/musl/${SLOT}/fix-bootjdk-check.patch"
		eapply "${FILESDIR}/musl/${SLOT}/ppc64le.patch"
		eapply "${FILESDIR}/musl/${SLOT}/aarch64.patch"
	fi

	# conditionally remove not compilable module (hotspot jdk.hotspot.agent)
	# this needs libthread_db which is only provided by glibc
	#
	# haven't found any way to disable this module so just remove it.
	if use elibc_musl; then
		rm -rf "${S}"/hotspot/src/jdk.hotspot.agent || die "failed to remove HotSpot agent"
	fi

	# https://bugs.openjdk.java.net/browse/JDK-8201788
	eapply "${FILESDIR}/bootcycle_jobs.patch"
	# https://bugs.openjdk.java.net/browse/JDK-8237879
	eapply "${FILESDIR}/patches/${SLOT}/make-4.3.patch"
	eapply "${FILESDIR}/patches/${SLOT}/pointer-comparison.patch"
	eapply "${FILESDIR}/patches/${SLOT}/aarch64_gcc_fix.patch"
	eapply "${FILESDIR}/patches/${SLOT}/fix-no-such-field-ipv6-error.patch"
}

src_configure() {
	# Work around -fno-common ( GCC10 default ), bug #706638
	append-flags -fcommon -fno-delete-null-pointer-checks -fno-lifetime-dse

	# Strip some flags users may set, but should not. #818502
	filter-flags -fexceptions

	tc-export_build_env CC CXX PKG_CONFIG STRIP

	# general build info found here:
	#https://hg.openjdk.java.net/jdk8/jdk8/raw-file/tip/README-builds.html

	# Work around stack alignment issue, bug #647954.
	use x86 && append-flags -mincoming-stack-boundary=2

	local myconf=(
			--disable-ccache
			--disable-warnings-as-errors
			--enable-unlimited-crypto
			--with-boot-jdk="${JDK_HOME}"
			--with-extra-cflags="${CFLAGS}"
			--with-extra-cxxflags="${CXXFLAGS}"
			--with-extra-ldflags="${LDFLAGS}"
			--with-giflib=system
			--disable-hotspot-gtest
			--disable-freetype-bundling
			--with-jtreg=no
			--with-jobs=1
			--with-num-cores=1
			--with-update-version="$(ver_cut 2)"
			--with-build-number="b$(ver_cut 4)"
			--with-milestone="fcs" # magic variable that means "release version"
			--with-zlib=system
			--with-native-debug-symbols=$(usex debug internal none)
			$(usex headless-awt --disable-headful '')
		)

	# PaX breaks pch, bug #601016
	if use pch && ! host-is-pax; then
		myconf+=( --enable-precompiled-headers )
	else
		myconf+=( --disable-precompiled-headers )
	fi

	(
		unset _JAVA_OPTIONS JAVA JAVA_TOOL_OPTIONS JAVAC XARGS
		CFLAGS= CXXFLAGS= LDFLAGS= \
		CONFIG_SITE=/dev/null \
		econf "${myconf[@]}"
	)
}

src_compile() {
	local myemakeargs=(
		JOBS=$(makeopts_jobs)
		LOG=debug
		$(usex doc docs '')
		images
	)
	emake "${myemakeargs[@]}" -j1 #nowarn
}

src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED%/}/${dest#/}"

	cd "${S}"/build/*-release/images/jdk || die

	# build system does not remove that
	if use headless-awt ; then
		rm -fvr jre/lib/$(get_system_arch)/lib*{[jx]awt,splashscreen}* \
		{,jre/}bin/policytool bin/appletviewer || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	dosym "${EPREFIX}"/etc/ssl/certs/java/cacerts "${dest}"/jre/lib/security/cacerts

	use gentoo-vm && java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		insinto /usr/share/doc/${PF}/html
		doins -r "${S}"/build/*-release/docs/*
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst

	if use gentoo-vm ; then
		ewarn "WARNING! You have enabled the gentoo-vm USE flag, making this JDK"
		ewarn "recognised by the system. This will almost certainly break things."
	else
		ewarn "The experimental gentoo-vm USE flag has not been enabled so this JDK"
		ewarn "will not be recognised by the system. For example, simply calling"
		ewarn "\"java\" will launch a different JVM. This is necessary until Gentoo"
		ewarn "fully supports Java ${SLOT}. This JDK must therefore be invoked using its"
		ewarn "absolute location under ${EPREFIX}/usr/$(get_libdir)/${PN}-${SLOT}."
	fi
}
