set -x 

SOURCE_DIR=$1
TARGET=$2

pushd ${SOURCE_DIR}
  git fetch upstream
  git checkout master
  git reset --hard upstream/master
popd

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
        sha256 = \"44453d398994a8d8fa540b2ffb5bbbb0a414c030236197e224ee6298adb53bdb\",
        strip_prefix = \"openssl-cbs-563fe95a2d5690934f903d9ebb3d9bbae40fc93f\",
        urls = [\"https://github.com/bdecoste/openssl-cbs/archive/563fe95a2d5690934f903d9ebb3d9bbae40fc93f.tar.gz\"],
    ),"
replace_text

FILE="bazel/repository_locations.bzl"
DELETE_START_PATTERN="boringssl_fips = dict("
DELETE_STOP_PATTERN="),"
START_OFFSET="0"
ADD_TEXT=""
replace_text

FILE="bazel/repository_locations.bzl"
DELETE_START_PATTERN="com_github_google_jwt_verify = dict("
DELETE_STOP_PATTERN="),"
START_OFFSET="0"
ADD_TEXT="    # EXTERNAL OPENSSL
    com_github_google_jwt_verify = dict(
        sha256 = \"40808d3a1cacdfc9827cc7d380386a69585c6b24bed82daa54918b176a2fde41\",
        strip_prefix = \"jwt_verify_lib-c3c4cbd5762b5da01ffc059262be38413311d070\",
        urls = [\"https://github.com/bdecoste/jwt_verify_lib/archive/c3c4cbd5762b5da01ffc059262be38413311d070.tar.gz\"],
    ),"
replace_text

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
    path = \"/usr/local/lib64/openssl\",
    build_file = \"openssl.BUILD\"
)"
echo "${OPENSSL_REPO}" >> ${SOURCE_DIR}/WORKSPACE

sed -i 's|go_register_toolchains(go_version = GO_VERSION)|go_register_toolchains(go_version = "host")|g' ${SOURCE_DIR}/WORKSPACE







