# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )
ADA_COMPAT=( gnat_201{7..9} gnat_202{0..1} )
inherit ada multiprocessing python-single-r1

MYP=${P}-${PV}0518-19B15-src
ADAMIRROR=https://community.download.adacore.com/v1
ID=d93655ced17f15c5f376b6861825df3f9c183980

DESCRIPTION="GNAT Component Collection"
HOMEPAGE="http://libre.adacore.com"
SRC_URI="${ADAMIRROR}/${ID}?filename=${MYP}.tar.gz -> ${MYP}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="gmp iconv python readline +shared static-libs static-pic syslog"

RDEPEND="python? ( ${PYTHON_DEPS} )
	${ADA_DEPS}
	dev-ada/gnatcoll-core[${ADA_USEDEP},shared?,static-libs?,static-pic?]
	gmp? ( dev-libs/gmp:* )"
DEPEND="${RDEPEND}
	dev-ada/gprbuild[${ADA_USEDEP}]"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	${ADA_REQUIRED_USE}"

S="${WORKDIR}"/${MYP}

pkg_setup() {
	use python && python-single-r1_pkg_setup
	ada_pkg_setup
}

src_prepare() {
	rm -rf python || die
	mv python3 python || die
	default
}

src_compile() {
	build () {
		gprbuild -j$(makeopts_jobs) -m -p -v \
			-XGPR_BUILD=$2 -XGNATCOLL_CORE_BUILD=$2 \
			-XLIBRARY_TYPE=$2 -P $1/gnatcoll_$1.gpr -XBUILD="PROD" \
			-XGNATCOLL_ICONV_OPT= \
			-XGNATCOLL_ICONV_OPT= -XGNATCOLL_PYTHON_CFLAGS="-I$(python_get_includedir)" \
			-XGNATCOLL_PYTHON_LIBS=$(python_get_library_path) \
			-cargs:Ada ${ADAFLAGS} -cargs:C ${CFLAGS} || die "gprbuild failed"
	}
	for kind in shared static-libs static-pic ; do
		if use $kind; then
			lib=${kind%-libs}
			lib=${lib/shared/relocatable}
			for dir in gmp iconv python readline syslog ; do
				if use $dir; then
					build $dir $lib
				fi
			done
		fi
	done
}

src_install() {
	build () {
		gprinstall -p -f -XBUILD=PROD --prefix="${D}"/usr -XLIBRARY_TYPE=$2 \
			-XGPR_BUILD=$2 -XGNATCOLL_CORE_BUILD=$2 \
			-XGNATCOLL_ICONV_OPT= -P $1/gnatcoll_$1.gpr --build-name=$2
	}
	for kind in shared static-libs static-pic ; do
		if use $kind; then
			lib=${kind%-libs}
			lib=${lib/shared/relocatable}
			for dir in gmp iconv python readline syslog ; do
				if use $dir; then
					build $dir $lib
				fi
			done
		fi
	done
	if use iconv; then
		sed -i \
			-e "s:GNATCOLL_ICONV_BUILD:LIBRARY_TYPE:" \
			"${D}"/usr/share/gpr/gnatcoll_iconv.gpr \
			|| die
	fi
	rm -r "${D}"/usr/share/gpr/manifests || die
	einstalldocs
}
