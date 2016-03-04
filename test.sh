set -e

bundle exec rake test

export BEAKER_debug=yes
export BEAKER_destroy=no

bundle exec rake acceptance
