#!/usr/bin/env bash

# This needs to be run in the root directory

# Cause the script to exit if a single command fails.
set -e
set -x

bazel build "//:gcs_client_test" "//:asio_test" "//:ray_redis_module.so" -c opt

# Start Redis.
if [[ "${RAY_USE_NEW_GCS}" = "on" ]]; then
    ./src/credis/redis/src/redis-server \
        --loglevel warning \
        --loadmodule ./src/credis/build/src/libmember.so \
        --loadmodule ./src/ray/gcs/redis_module/libray_redis_module.so \
        --port 6379 &
else
    ./bazel-genfiles/ray_pkg/ray/core/src/ray/thirdparty/redis/src/redis-server \
        --loglevel warning \
        --loadmodule ./bazel-bin/ray_redis_module.so \
        --port 6379 &
fi
sleep 1s

./bazel-bin/gcs_client_test
./bazel-bin/asio_test

./bazel-genfiles/ray_pkg/ray/core/src/ray/thirdparty/redis/src/redis-cli -p 6379 shutdown
sleep 1s
