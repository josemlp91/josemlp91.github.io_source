#!/bin/sh

set -o errexit
set -o nounset

bundle install

exec "$@"