#!/bin/sh
# Passed to comparator as COMPARATOR_LANDRUN. Runs the real landrun with comparator's
# arguments unchanged, plus one environment variable that caps how many files Lake
# compiles at once (memory). It adds no filesystem or network permissions.
exec /usr/local/bin/landrun --env "LEAN_NUM_THREADS=${QRH_LEAN_THREADS:?set QRH_LEAN_THREADS}" "$@"
