# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic git-r3 llvm rust-toolchain

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

MRUSTC_VERSION="0.10"
EGIT_REPO_URI="https://github.com/thepowersgang/mrustc.git"
EGIT_COMMIT="1b1416bb2b44e2c331c7201833305cac29d571e8"


SRC_URI="
	https://static.rust-lang.org/dist/rustc-${PV}-src.tar.xz"
	#https://github.com/thepowersgang/mrustc/archive/v${MRUSTC_VERSION}.tar.gz"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"
SLOT="stable/1.54"
KEYWORDS="amd64"
DEPEND="
	dev-util/cmake
	sys-process/time
"

RDEPEND=""

LLVM_TARGETS="AArch64;ARM;X86"

S=${WORKDIR}/mrustc-${MRUSTC_VERSION}

RUSTC_VERSION=1.54.0
MRUSTC_TARGET_VER=1.54
OUTDIR_SUF=

src_unpack() {
	git-r3_fetch "${EGIT_REPO_URI}" "${EGIT_COMMIT}"
	git-r3_checkout "${EGIT_REPO_URI}" "${S}"
	unpack ${A}
	mv rustc-${PV}-src ${S}
}

src_prepare() {
	cd ${S}

	pushd ${S}/rustc-${PV}-src
	rm "vendor/vte/vim10m_"{match,table}
	eapply -p0 ${S}/rustc-${PV}-src.patch
	sed -i 's/ $(RUSTC_SRC_DL)//' "${S}/minicargo.mk"
	popd

	eapply_user
}

src_configure() {
	default
}

src_compile() {
	local -a make_opts
	make_opts=(RUSTC_VERSION=${RUSTC_VERSION} MRUSTC_TARGET_VER=${MRUSTC_TARGET_VER} OUTDIR_SUF=${OUTDIR_SUF} RUSTC_TARGET=$(rust_abi))
	emake ${make_opts[@]} || die "compile problem"
	emake -j1 ${make_opts[@]} -f minicargo.mk LIBS || die "compile problem"
RUSTC_TARGET=$(rust_abi) || die "compile problem"
	emake -j1 ${make_opts[@]} test || die "compile problem"
	emake -j1 ${make_opts[@]} local_tests || die "compile problem"
	emake -j1 ${make_opts[@]} RUSTC_INSTALL_BINDIR=bin -f minicargo.mk "output/rustc" || die "compile problem"
	emake -j1 ${make_opts[@]} LIBGIT2_SYS_USE_PKG_CONFIG=1 -f minicargo.mk "output${OUTDIR_SUF}/cargo" || die "compile problem"

	emake -C run_rustc -j1 ${make_opts[@]} || die "compile problem"
}

src_install() {
	mkdir -p "${D}/usr/"{bin,lib}/
	rustc_wrapper="${S}/run_rustc/output/prefix/bin/rustc"
	sed -i '/LD_LIBRARY_PATH/c\LD_LIBRARY_PATH="$d\/..\/lib\/rustlib\/'$(rust_abi)'\/lib" $d\/rustc_binary $@' ${rustc_wrapper}
	cp -R "${rustc_wrapper}" "${D}/usr/bin/rustc-${PV}" || die "Install failed!"
	cp -R "${S}/run_rustc/output/prefix/bin/rustc_binary" "${D}/usr/bin/rustc_binary" || die "Install failed!"
	cp -R "${S}/run_rustc/output/prefix/bin/cargo" "${D}/usr/bin/cargo-${PV}" || die "Install failed!"
	cp -R "${S}/run_rustc/output/prefix/lib/rustlib" "${D}/usr/lib/rustlib" || die "Install failed!"
	mkdir -p "${D}/etc/env.d/rust/"
	echo /usr/bin/cargo >> "${D}/etc/env.d/rust/provider-rust-${PV}"
}
