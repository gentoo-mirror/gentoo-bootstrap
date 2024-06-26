# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit check-reqs flag-o-matic java-pkg-2 java-vm-2 multiprocessing toolchain-funcs

# don't change versioning scheme
# to find correct _p number, look at
# https://github.com/openjdk/jdk${SLOT}u/tags
# you will see, for example, jdk-17.0.4.1-ga and jdk-17.0.4.1+1, both point
# to exact same commit sha. we should always use the full version.
# -ga tag is just for humans to easily identify General Availability release tag.
# we need -ga tag to fetch tarball and unpack it, but exact number everywhere else to
# set build version properly
MY_PV="${PV%_p*}-ga"
SLOT="${MY_PV%%[.+]*}"


DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.java.net"
SRC_URI="
	https://github.com/${PN}/jdk${SLOT}u/archive/refs/tags/jdk-${MY_PV}.tar.gz
		-> ${P}.tar.gz"

LICENSE="GPL-2-with-classpath-exception"
KEYWORDS="amd64 ~arm arm64 ~ppc64"

IUSE="alsa cups debug doc examples headless-awt javafx selinux source systemtap"

COMMON_DEPEND="
	media-libs/freetype:2=
	media-libs/giflib:0/7
	media-libs/libpng:0=
	media-libs/lcms:2=
	sys-libs/zlib
	virtual/jpeg:0=
	systemtap? ( dev-util/systemtap )
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
		x11-libs/libXrandr
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
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	javafx? ( dev-java/openjfx:${SLOT}= )
	|| (
		dev-java/openjdk-bin:${SLOT}
		dev-java/openjdk:${SLOT}
		dev-java/openjdk-bin:$((SLOT-1))
		dev-java/openjdk:$((SLOT-1))
	)
"

REQUIRED_USE="javafx? ( alsa !headless-awt )"

S="${WORKDIR}/jdk${SLOT}u-jdk-${MY_PV}"

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
	if [[ ${MERGE_TYPE} != binary ]]; then
		has ccache ${FEATURES} && die "FEATURES=ccache doesn't work with ${PN}"
	fi
}

pkg_setup() {
	openjdk_check_requirements
	java-vm-2_pkg_setup

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} openjdk-bin-${SLOT} openjdk-$((SLOT-1)) openjdk-bin-$((SLOT-1))"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	for vm in ${JAVA_PKG_WANT_BUILD_VM}; do
		if [[ -d ${EPREFIX}/usr/lib/jvm/${vm} ]]; then
			java-pkg-2_pkg_setup
			return
		fi
	done
}

src_prepare() {
	default

	# conditionally apply patches for musl compatibility
	if use elibc_musl; then
		eapply "${FILESDIR}/musl/${SLOT}/build.patch"
		eapply "${FILESDIR}/musl/${SLOT}/ppc64le.patch"
		eapply "${FILESDIR}/musl/${SLOT}/aarch64.patch"
	fi

	# conditionally remove not compilable module (hotspot jdk.hotspot.agent)
	# this needs libthread_db which is only provided by glibc
	#
	# haven't found any way to disable this module so just remove it.
	if use elibc_musl; then
		rm -rf "${S}"/src/jdk.hotspot.agent || die "failed to remove HotSpot agent"
	fi

	chmod +x configure || die
}

src_configure() {
	# Work around stack alignment issue, bug #647954. in case we ever have x86
	use x86 && append-flags -mincoming-stack-boundary=2

	# Work around -fno-common ( GCC10 default ), bug #713180
	append-flags -fcommon

	# Strip lto related flags, we rely on USE=lto and --with-jvm-features=link-time-opt
	# https://bugs.gentoo.org/833097
	# https://bugs.gentoo.org/833098
	filter-lto
	filter-flags -fdevirtualize-at-ltrans

	# Enabling full docs appears to break doc building. If not
	# explicitly disabled, the flag will get auto-enabled if pandoc and
	# graphviz are detected. pandoc has loads of dependencies anyway.

	local myconf=(
		--disable-ccache
		--disable-precompiled-headers
		--disable-warnings-as-errors
		--enable-full-docs=no
		--with-boot-jdk="${JDK_HOME}"
		--with-extra-cflags="${CFLAGS}"
		--with-extra-cxxflags="${CXXFLAGS}"
		--with-extra-ldflags="${LDFLAGS}"
		--with-freetype="${XPAK_BOOTSTRAP:-system}"
		--with-giflib="${XPAK_BOOTSTRAP:-system}"
		--with-lcms="${XPAK_BOOTSTRAP:-system}"
		--with-libjpeg="${XPAK_BOOTSTRAP:-system}"
		--with-libpng="${XPAK_BOOTSTRAP:-system}"
		--with-native-debug-symbols=$(usex debug internal none)
		--with-vendor-name="Gentoo"
		--with-vendor-url="https://gentoo.org"
		--with-vendor-bug-url="https://bugs.gentoo.org"
		--with-vendor-vm-bug-url="https://bugs.openjdk.java.net"
		--with-vendor-version-string="${PVR}"
		--with-version-pre=""
		--with-version-string="${PV%_p*}"
		--with-version-build="${PV#*_p}"
		--with-zlib="${XPAK_BOOTSTRAP:-system}"
		--enable-dtrace=$(usex systemtap yes no)
		--enable-headless-only=$(usex headless-awt yes no)
		$(tc-is-clang && echo "--with-toolchain-type=clang")
	)

	if use javafx; then
		# this is not useful for users, just for upstream developers
		# build system compares mesa version in md file
		# https://bugs.gentoo.org/822612
		export LEGAL_EXCLUDES=mesa3d.md

		local zip="${EPREFIX%/}/usr/$(get_libdir)/openjfx-${SLOT}/javafx-exports.zip"
		if [[ -r ${zip} ]]; then
			myconf+=( --with-import-modules="${zip}" )
		else
			die "${zip} not found or not readable"
		fi
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
		NICE= # Use PORTAGE_NICENESS, don't adjust further down
		ALL_NAMED_TESTS= # Build error
		$(usex doc docs '')
		product-images
	)
	emake "${myemakeargs[@]}" -j1 #nowarn
}

src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED}/${dest#/}"

	cd "${S}"/build/*-release/images/jdk || die

	# Create files used as storage for system preferences.
	mkdir .systemPrefs || die
	touch .systemPrefs/.system.lock || die
	touch .systemPrefs/.systemRootModFile || die

	# Oracle and IcedTea have libjsoundalsa.so depending on
	# libasound.so.2 but OpenJDK only has libjsound.so. Weird.
	if ! use alsa ; then
		rm -v lib/libjsound.* || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	rm -v lib/security/cacerts || die

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	dosym ../../../../../etc/ssl/certs/java/cacerts "${dest}"/lib/security/cacerts

	# must be done before running itself
	java-vm_set-pax-markings "${ddest}"

	einfo "Creating the Class Data Sharing archives and disabling usage tracking"
	"${ddest}/bin/java" -server -Xshare:dump -Djdk.disableLastUsageTracking || die

	java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		docinto html
		dodoc -r "${S}"/build/*-release/images/docs/*
		dosym ../../../usr/share/doc/"${PF}" /usr/share/doc/"${PN}-${SLOT}"
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst
}
