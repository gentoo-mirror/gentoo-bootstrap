# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic eutils git-r3 llvm

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

# MRUSTC_VERSION="0.9"
EGIT_REPO_URI="https://github.com/stikonas/mrustc.git"
# EGIT_REPO_URI="https://github.com/thepowersgang/mrustc.git"
EGIT_COMMIT="3e6e406fdf50ce8cbfe54ff3a23e707758da0708"

SRC_URI="
	https://static.rust-lang.org/dist/rustc-${PV}-src.tar.xz"
# 	https://github.com/thepowersgang/mrustc/archive/v${MRUSTC_VERSION}.tar.gz

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"
SLOT="stable/1.29"
KEYWORDS="amd64 arm64"
DEPEND="dev-util/cmake"
RDEPEND=""

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC RISCV Sparc SystemZ WebAssembly X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

IUSE="${ALL_LLVM_TARGETS[*]}"

S=${WORKDIR}/mrustc-${MRUSTC_VERSION}

src_unpack() {
        git-r3_fetch "${EGIT_REPO_URI}" "${EGIT_COMMIT}"
        git-r3_checkout "${EGIT_REPO_URI}" "${S}"
	unpack ${A}
	mv rustc-${PV}-src ${S}
}

src_prepare() {
	cd ${S}
	sed -i 's/\$Vtime/\$V/' run_rustc/Makefile

	cd ${S}/rustc-${PV}-src
	eapply -p0 ${S}/rustc-${PV}-src.patch

	eapply_user
}

src_configure() {
	default
}

src_compile() {
	emake RUSTC_TARGET=x86_64-unknown-linux-gnu -f minicargo.mk || die "compile problem"
	emake RUSTC_TARGET=x86_64-unknown-linux-gnu -f minicargo.mk output/cargo || die "compile problem"
	cd run_rustc
	emake RUSTC_TARGET=x86_64-unknown-linux-gnu || die "compile problem"
}

src_install() {
	mkdir -p "${D}/usr/bin/"
	cp -R "${S}/run_rustc/output/prefix-s/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die "Install failed!"
	cp -R "${S}/output/cargo" "${D}/usr/bin/cargo-${PV}" || die "Install failed!"
	cp -R "${S}/run_rustc/output/prefix-s/lib" "${D}/usr" || die "Install failed!"
	mkdir -p "${D}/etc/env.d/rust/"
	echo /usr/bin/cargo >> "${D}/etc/env.d/rust/provider-rust-${PV}"
}
