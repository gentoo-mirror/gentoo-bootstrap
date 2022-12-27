# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic git-r3 llvm rust-toolchain

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

# MRUSTC_VERSION="0.9"
EGIT_REPO_URI="https://github.com/thepowersgang/mrustc.git"
EGIT_COMMIT="8f7baf68165571d381ddb47bef19eb4cd672924c"

SRC_URI="
	https://static.rust-lang.org/dist/rustc-${PV}-src.tar.xz"
# 	https://github.com/thepowersgang/mrustc/archive/v${MRUSTC_VERSION}.tar.gz

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"
SLOT="stable/1.39"
KEYWORDS="amd64"
DEPEND="
	dev-util/cmake
	sys-process/time
"

RDEPEND=""

LLVM_TARGETS="AArch64;ARM;X86"

S=${WORKDIR}/mrustc-${MRUSTC_VERSION}

RUSTC_VERSION=1.39.0
MRUSTC_TARGET_VER=1.39
OUTDIR_SUF=-1.39.0

src_unpack() {
	git-r3_fetch "${EGIT_REPO_URI}" "${EGIT_COMMIT}"
	git-r3_checkout "${EGIT_REPO_URI}" "${S}"
	unpack ${A}
	mv rustc-${PV}-src ${S}
}

src_prepare() {
	cd ${S}

	cd ${S}/rustc-${PV}-src
	eapply -p0 ${S}/rustc-${PV}-src.patch

	eapply_user
}

src_configure() {
	default
}

src_compile() {
	emake RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi) -f minicargo.mk LIBS || die "compile problem"
	emake RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi) -f minicargo.mk || die "compile problem"
	emake RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi) -f minicargo.mk "output${OUTDIR_SUF}/rustc" || die "compile problem"
	emake RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi) LIBGIT2_SYS_USE_PKG_CONFIG=1 -f minicargo.mk "output${OUTDIR_SUF}/cargo" || die "compile problem"
	cd run_rustc
	# -j1 workaround for broken jobserver
	emake -j1 RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi) || die "compile problem"
}

src_install() {
	mkdir -p "${D}/usr/bin/"
	rustc_wrapper="${S}/run_rustc/output${OUTDIR_SUF}/prefix/bin/rustc"
	sed -i '/LD_LIBRARY_PATH/c\LD_LIBRARY_PATH="$d\/..\/lib\/rustlib\/'$(rust_abi)'\/lib" $d\/rustc_binary $@' ${rustc_wrapper}
	cp -R "${rustc_wrapper}" "${D}/usr/bin/rustc-${PV}" || die "Install failed!"
	cp -R "${S}/run_rustc/output${OUTDIR_SUF}/prefix/bin/rustc_binary" "${D}/usr/bin/rustc_binary" || die "Install failed!"
	cp -R "${S}/run_rustc/output${OUTDIR_SUF}/prefix/bin/cargo" "${D}/usr/bin/cargo-${PV}" || die "Install failed!"
	cp -R "${S}/run_rustc/output${OUTDIR_SUF}/prefix/lib" "${D}/usr" || die "Install failed!"
	mkdir -p "${D}/etc/env.d/rust/"
	echo /usr/bin/cargo >> "${D}/etc/env.d/rust/provider-rust-${PV}"
}
