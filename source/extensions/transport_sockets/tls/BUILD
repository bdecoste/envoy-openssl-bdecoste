licenses(["notice"])  # Apache 2

# Built-in TLS connection transport socket.

load(
    "//bazel:envoy_build_system.bzl",
    "envoy_cc_library",
    "envoy_package",
)

envoy_package()

envoy_cc_library(
    name = "config",
    srcs = ["config.cc"],
    hdrs = ["config.h"],
    deps = [
        ":ssl_socket_lib",
        "//include/envoy/network:transport_socket_interface",
        "//include/envoy/registry",
        "//include/envoy/server:transport_socket_config_interface",
        "//source/extensions/transport_sockets:well_known_names",
    ],
)

envoy_cc_library(
    name = "ssl_socket_lib",
    srcs = ["ssl_socket.cc"],
    hdrs = ["ssl_socket.h"],
    external_deps = [
        "abseil_optional",
        "abseil_synchronization",
        "ssl",
        "bssl_wrapper_lib",
    ],
    deps = [
        ":context_config_lib",
        ":context_lib",
        ":utility_lib",
        "//include/envoy/network:connection_interface",
        "//include/envoy/network:transport_socket_interface",
        "//include/envoy/stats:stats_macros",
        "//source/common/common:assert_lib",
        "//source/common/common:empty_string",
        "//source/common/common:minimal_logger_lib",
        "//source/common/common:thread_annotations",
        "//source/common/http:headers_lib",
    ],
)

envoy_cc_library(
    name = "context_config_lib",
    srcs = ["context_config_impl.cc"],
    hdrs = ["context_config_impl.h"],
    external_deps = [
        "ssl",
    ],
    deps = [
        "//include/envoy/secret:secret_callbacks_interface",
        "//include/envoy/secret:secret_provider_interface",
        "//include/envoy/server:transport_socket_config_interface",
        "//include/envoy/ssl:context_config_interface",
        "//source/common/common:assert_lib",
        "//source/common/common:empty_string",
        "//source/common/config:datasource_lib",
        "//source/common/config:tls_context_json_lib",
        "//source/common/json:json_loader_lib",
        "//source/common/protobuf:utility_lib",
        "//source/common/secret:sds_api_lib",
        "//source/common/ssl:certificate_validation_context_config_impl_lib",
        "//source/common/ssl:tls_certificate_config_impl_lib",
        "@envoy_api//envoy/api/v2/auth:cert_cc",
    ],
)

envoy_cc_library(
    name = "context_lib",
    srcs = [
        "context_impl.cc",
        "context_manager_impl.cc",
    ],
    hdrs = [
        "context_impl.h",
        "context_manager_impl.h",
    ],
    external_deps = [
        "abseil_synchronization",
        "ssl",
        "bssl_wrapper_lib",
    ],
    deps = [
        ":openssl_impl_lib",
        ":utility_lib",
        "//include/envoy/stats:stats_interface",
        "//include/envoy/stats:stats_macros",
        "//include/envoy/ssl:context_config_interface",
        "//include/envoy/ssl:context_interface",
        "//include/envoy/ssl:context_manager_interface",
        "//source/common/common:assert_lib",
        "//source/common/common:base64_lib",
        "//source/common/common:hex_lib",
        "//source/common/common:utility_lib",
        "//source/common/protobuf:utility_lib",
        "@envoy_api//envoy/admin/v2alpha:certs_cc",
    ],
)

envoy_cc_library(
    name = "utility_lib",
    srcs = ["utility.cc"],
    hdrs = ["utility.h"],
    external_deps = [
        "ssl",
        "bssl_wrapper_lib",
    ],
    deps = [
        ":openssl_impl_lib",
        "//source/common/common:assert_lib",
        "//source/common/common:utility_lib",
    ],
)

envoy_cc_library(
    name = "openssl_impl_lib",
    srcs = [
        "openssl_impl.cc",
    ],
    hdrs = [
        "openssl_impl.h",
    ],
    external_deps = [
        "ssl",
        "bssl_wrapper_lib",
    ],
)
