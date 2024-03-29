set -x 

SOURCE_DIR=$1
TARGET=$2

if [ "${GIT_RESET}" == "true" ]; then
  pushd ${SOURCE_DIR}
    git fetch upstream
    git checkout master
    git reset --hard upstream/master
  popd
fi

if [ "$TARGET" == "RESET" ]; then
  exit
fi

BUILD_OPTIONS="
build --cxxopt -D_GLIBCXX_USE_CXX11_ABI=1
build --cxxopt -DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1
build --cxxopt -Wnon-virtual-dtor
build --cxxopt -Wformat
build --cxxopt -Wformat-security
build --cxxopt -Wno-error=old-style-cast
build --cxxopt -Wno-error=deprecated-declarations
build --cxxopt -Wno-error=unused-variable
build --cxxopt -w
build --cxxopt -ldl
"
echo "${BUILD_OPTIONS}" >> ${SOURCE_DIR}/.bazelrc

if [ "$TARGET" == "BORINGSSL" ]; then
  exit
fi

rm -rf ${SOURCE_DIR}/source/extensions/transport_sockets/tls
rm -rf ${SOURCE_DIR}/source/extensions/filters/listener/tls_inspector
rm -rf ${SOURCE_DIR}/test/extensions/transport_sockets/tls
rm -rf ${SOURCE_DIR}/test/extensions/filters/listener/tls_inspector
cp -rf source/extensions/transport_sockets/tls ${SOURCE_DIR}/source/extensions/transport_sockets/
cp -rf source/extensions/filters/listener/tls_inspector ${SOURCE_DIR}/source/extensions/filters/listener/
cp -rf test/extensions/transport_sockets/tls ${SOURCE_DIR}/test/extensions/transport_sockets/
cp -rf test/extensions/filters/listener/tls_inspector ${SOURCE_DIR}/test/extensions/filters/listener/

cp openssl.BUILD ${SOURCE_DIR}

function replace_text() {
  START=$(grep -nr "${DELETE_START_PATTERN}" ${SOURCE_DIR}/${FILE} | cut -d':' -f1)
  START=$((${START} + ${START_OFFSET}))
  if [[ ! -z "${DELETE_STOP_PATTERN}" ]]; then
    STOP=$(tail --lines=+${START}  ${SOURCE_DIR}/${FILE} | grep -nr "${DELETE_STOP_PATTERN}" - |  cut -d':' -f1 | head -1)
    CUT=$((${START} + ${STOP} - 1))
  else
    CUT=$((${START}))
  fi
  CUT_TEXT=$(sed -n "${START},${CUT} p" ${SOURCE_DIR}/${FILE})
  sed -i "${START},${CUT} d" ${SOURCE_DIR}/${FILE}

  if [[ ! -z "${ADD_TEXT}" ]]; then
    ex -s -c "${START}i|${ADD_TEXT}" -c x ${SOURCE_DIR}/${FILE}
  fi
}

FILE="bazel/repository_locations.bzl"
DELETE_START_PATTERN="boringssl = dict("
DELETE_STOP_PATTERN="),"
START_OFFSET="0"
ADD_TEXT="    #EXTERNAL OPENSSL
    bssl_wrapper = dict(
        sha256 = \"d9e500e1a8849c81e690966422baf66016a7ff85d044c210ad85644f62827158\",
        strip_prefix = \"bssl_wrapper-34df33add45e1a02927fcf79b0bdd5899b7e2e36\",
        urls = [\"https://github.com/bdecoste/bssl_wrapper/archive/34df33add45e1a02927fcf79b0bdd5899b7e2e36.tar.gz\"],
    ),
    #EXTERNAL OPENSSL
    openssl_cbs = dict(
        strip_prefix = \"openssl-cbs-c81c75e7ec037605ef9b10587f6a59ba584a1b84\",
        urls = [\"https://github.com/bdecoste/openssl-cbs/archive/c81c75e7ec037605ef9b10587f6a59ba584a1b84.tar.gz\"],
        sha256 = \"ebe7aca5c1068358b854d1be684d087f29a09832e67ae207f4539b7d261ae9d2\",
    ),"
replace_text

FILE="bazel/repository_locations.bzl"
DELETE_START_PATTERN="boringssl_fips = dict("
DELETE_STOP_PATTERN="),"
START_OFFSET="0"
ADD_TEXT=""
replace_text

if [ "$UPDATE_JWT" == "true" ]; then
  FILE="bazel/repository_locations.bzl"
  DELETE_START_PATTERN="com_github_google_jwt_verify = dict("
  DELETE_STOP_PATTERN="),"
  START_OFFSET="0"
  ADD_TEXT="    # EXTERNAL OPENSSL
    com_github_google_jwt_verify = dict(
        sha256 = \"b42c1809576c800a44a2715fb500b70422c7067d890cb2de4ec6b8a11806f5e2\",
        strip_prefix = \"jwt_verify_lib-b3e37f05ecf3590ac95f889e2dc8f64029718e5b\",
        urls = [\"https://github.com/bdecoste/jwt_verify_lib/archive/b3e37f05ecf3590ac95f889e2dc8f64029718e5b.tar.gz\"],
    ),"
  replace_text
fi

FILE="bazel/repositories.bzl"
DELETE_START_PATTERN="def _boringssl():"
DELETE_STOP_PATTERN=" )"
START_OFFSET="0"
ADD_TEXT="#EXTERNAL OPENSSL
def _openssl():
    native.bind(
        name = \"ssl\",
        actual = \"@openssl//:openssl-lib\",
)

#EXTERNAL OPENSSL
def _bssl_wrapper():
    _repository_impl(\"bssl_wrapper\")
    native.bind(
        name = \"bssl_wrapper_lib\",
        actual = \"@bssl_wrapper//:bssl_wrapper_lib\",
    )

#EXTERNAL OPENSSL
def _openssl_cbs():
    _repository_impl(\"openssl_cbs\")
    native.bind(
        name = \"openssl_cbs_lib\",
        actual = \"@openssl_cbs//:openssl_cbs_lib\",
    )"
replace_text

FILE="bazel/repositories.bzl"
DELETE_START_PATTERN="_boringssl()"
DELETE_STOP_PATTERN=""
START_OFFSET="0"
ADD_TEXT="
    # EXTERNAL OPENSSL
    _openssl()
    _bssl_wrapper()
    _openssl_cbs()

"
replace_text

FILE="bazel/repositories.bzl"
DELETE_START_PATTERN="_boringssl_fips()"
DELETE_STOP_PATTERN=")"
START_OFFSET="0"
ADD_TEXT=""
replace_text

FILE="bazel/repositories.bzl"
DELETE_START_PATTERN="@envoy//bazel:boringssl"
DELETE_STOP_PATTERN=")"
START_OFFSET="-2"
ADD_TEXT=""
replace_text

OPENSSL_REPO="
new_local_repository(
    name = \"openssl\",
    path = \"/usr/lib64/\",
    build_file = \"openssl.BUILD\"
)"
echo "${OPENSSL_REPO}" >> ${SOURCE_DIR}/WORKSPACE

sed -i 's|go_register_toolchains(go_version = GO_VERSION)|go_register_toolchains(go_version = "host")|g' ${SOURCE_DIR}/WORKSPACE

sed -i 's|#include "openssl/base.h"|#include "opensslcbs/cbs.h"|g' ${SOURCE_DIR}/source/extensions/quic_listeners/quiche/platform/quic_cert_utils_impl.h
sed -i 's|#include "openssl/bytestring.h"|#include "opensslcbs/cbs.h"|g' ${SOURCE_DIR}/source/extensions/quic_listeners/quiche/platform/quic_cert_utils_impl.cc

FILE="source/extensions/quic_listeners/quiche/platform/BUILD"
DELETE_START_PATTERN="\"quiche_quic_platform_base\","
DELETE_STOP_PATTERN=""
START_OFFSET="0"
ADD_TEXT="        \"quiche_quic_platform_base\",
        \"openssl_cbs_lib\","
replace_text







