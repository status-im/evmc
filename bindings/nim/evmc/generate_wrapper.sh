#!/bin/bash

# Copyright (c) 2020 Status Research & Development GmbH
# Licensed under the Apache License, Version 2.0.
# This file may not be copied, modified, or distributed except according to
# those terms.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

sed -e '/^#include/d' \
	-e '/^struct evmc_result;$/d' \
	-e '/^struct evmc_vm;$/d' \
	../../../include/evmc/evmc.h | cpp | sed '/^#/d' > tmp.h

c2nim --header:'"evmc/evmc.h"' --cdecl tmp.h

rm tmp.h

sed \
	-e 's/uint8_t/uint8/g' \
	-e 's/uint32_t/uint32/g' \
	-e 's/int32_t/int32/g' \
	-e 's/int64_t/int64/g' \
	-e 's/csize/uint/g' \
	-e 's/EVMC_MAX_REVISION/EVMC_MAX_REVISION*/' \
	-e 's/"evmc_message"/"struct evmc_message"/' \
	-e 's/"evmc_tx_context"/"struct evmc_tx_context"/' \
	-e 's/"evmc_host_context"/"struct evmc_host_context"/' \
	-e 's/"evmc_result"/"struct evmc_result"/' \
	-e 's/"evmc_host_interface"/"struct evmc_host_interface"/' \
	-e 's/"evmc_vm"/"struct evmc_vm"/' \
	tmp.nim | gawk '
/^const$/ {
	target = "const"
}
/^type$/ {
	target = "type"
}
/^ / {
	if(target == "const")
		consts[const_index++] = $0
	else if(target == "type")
		types[type_index++] = $0
}
END {
	print "type"
	for(i in types)
		print types[i]
	print "\nconst"
	for(i in consts)
		print consts[i]
}
' > evmc.nim
rm tmp.nim

