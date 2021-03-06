# Copyright (c) 2018-2020 Status Research & Development GmbH
# Licensed under the Apache License, Version 2.0.
# This file may not be copied, modified, or distributed except according to
# those terms.

import tables, hashes, strutils,
  stew/byteutils,
  ../evmc/evmc

type
  Account = ref object
    balance: evmc_uint256be
    code: seq[byte]
    storage: Table[evmc_bytes32, evmc_bytes32]

  HostContext = ref object
    tx_context: evmc_tx_context
    accounts: Table[evmc_address, Account]

const
  EVMC_HOST_NAME = "example_vm"
  EVMC_VM_VERSION = "0.0.0"

# {.nodecl.} only works in the global scope
var globalVM {.importc, nodecl.}: evmc_vm
# Nim doesn't support initialising a struct with const fields, so we do it in C
{.emit: [evmc_vm, " ", globalVM, " = {.abi_version = ", EVMC_ABI_VERSION, ", .name = \"", EVMC_HOST_NAME, "\", .version = \"", EVMC_VM_VERSION, "\"};"].}

proc incl*(a: var evmc_capabilities_flagset, b: evmc_capabilities) {.inline.} =
  a = evmc_capabilities_flagset(a.uint32 or b.uint32)

proc excl*(a: var evmc_capabilities_flagset, b: evmc_capabilities) {.inline.} =
  a = evmc_capabilities_flagset(a.uint32 and (not b.uint32))

proc contains*(a: evmc_capabilities_flagset, b: evmc_capabilities): bool {.inline.} =
  (a.uint32 and b.uint32) != 0

proc hash*(x: evmc_bytes32): Hash =
  result = hash(x.bytes)

proc hash*(x: evmc_address): Hash =
  result = hash(x.bytes)

proc codeHash(acc: Account): evmc_bytes32 =
  # Extremely dumb "hash" function.
  for v in acc.code:
    let idx = v.int mod sizeof(result.bytes)
    result.bytes[idx] = result.bytes[idx] xor v

proc evmcReleaseResultImpl(result: ptr evmc_result) {.cdecl.} =
  discard

converter toEVMCHostContext*(ctx: HostContext): ptr evmc_host_context =
  cast[ptr evmc_host_context](ctx)

proc evmcGetTxContextImpl(ctx: HostContext): evmc_tx_context {.cdecl.} =
  ctx.tx_context

proc evmcGetBlockHashImpl(ctx: HostContext, number: int64): evmc_bytes32 {.cdecl.} =
  const hash = hexToByteArray[32]("0xb10c8a5fb10c8a5fb10c8a5fb10c8a5fb10c8a5fb10c8a5fb10c8a5fb10c8a5f")
  let current_block_number = ctx.tx_context.block_number
  if number < current_block_number and number >= current_block_number - 256:
    result.bytes = hash

proc evmcAccountExistsImpl(ctx: HostContext, address: var evmc_address): bool {.cdecl.} =
  address in ctx.accounts

proc evmcGetStorageImpl(ctx: HostContext, address: var evmc_address, key: var evmc_bytes32): evmc_bytes32 {.cdecl.} =
  if address in ctx.accounts:
    result = ctx.accounts[address].storage[key]

proc evmcSetStorageImpl(ctx: HostContext, address: var evmc_address,
                        key, value: var evmc_bytes32): evmc_storage_status {.cdecl.} =

  if address in ctx.accounts:
    var acc = ctx.accounts[address]
    let prev_value = acc.storage.getOrDefault(key)
    acc.storage[key] = value
    result = if prev_value == value: EVMC_STORAGE_UNCHANGED else: EVMC_STORAGE_MODIFIED
  else:
    var acc = Account()
    acc.storage[key] = value
    ctx.accounts[address] = acc
    result = EVMC_STORAGE_MODIFIED

proc evmcGetBalanceImpl(ctx: HostContext, address: var evmc_address): evmc_uint256be {.cdecl.} =
  if address in ctx.accounts:
    result = ctx.accounts[address].balance

proc evmcGetCodeSizeImpl(ctx: HostContext, address: var evmc_address): uint {.cdecl.} =
  if address in ctx.accounts:
    result = ctx.accounts[address].code.len.uint

proc evmcGetCodeHashImpl(ctx: HostContext, address: var evmc_address): evmc_bytes32 {.cdecl.} =
  if address in ctx.accounts:
    result = ctx.accounts[address].codeHash()

proc evmcCopyCodeImpl(ctx: HostContext, address: var evmc_address,
                            code_offset: uint, buffer_data: ptr byte,
                            buffer_size: uint): uint {.cdecl.} =

  if address notin ctx.accounts:
    return 0

  let acc = ctx.accounts[address]
  if code_offset.int >= acc.code.len:
    return 0

  let n = min(buffer_size.int, acc.code.len - code_offset.int)
  if n > 0:
    copyMem(buffer_data, acc.code[code_offset].addr, n)
  result = n.uint

proc evmcSelfdestructImpl(ctx: HostContext, address, beneficiary: var evmc_address) {.cdecl.} =
  discard

proc evmcEmitLogImpl(ctx: HostContext, address: var evmc_address,
                           data: ptr byte, data_size: uint,
                           topics: ptr evmc_bytes32, topics_count: uint) {.cdecl.} =
  discard

proc evmcCallImpl(ctx: HostContext, msg: var evmc_message): evmc_result {.cdecl.} =
  result = evmc_result(status_code: EVMC_REVERT, gas_left: msg.gas, output_data: msg.input_data, output_size: msg.input_size)

proc evmcSetOptionImpl(vm: ptr evmc_vm, name, value: cstring): evmc_set_option_result {.cdecl.} =
  let name = $name

  if name == "verbose":
    if value == nil:
      return EVMC_SET_OPTION_INVALID_VALUE
    try:
      discard parseInt($value)
      return EVMC_SET_OPTION_SUCCESS
    except:
      return EVMC_SET_OPTION_INVALID_VALUE

  return EVMC_SET_OPTION_INVALID_NAME

proc evmcExecuteImpl(vm: ptr evmc_vm, host: ptr evmc_host_interface,
                          ctx: HostContext, rev: evmc_revision,
                          msg: ptr evmc_message, code: ptr byte, code_size: uint): evmc_result {.cdecl.} =

  var the_code = "\x43\x60\x00\x55\x43\x60\x00\x52\x59\x60\x00\xf3"
  if (code_size.int == the_code.len) and equalMem(code, the_code[0].addr, code_size):
    let tx_context = ctx.tx_context
    let output_size = 20
    var value, key: evmc_bytes32
    value.bytes[31] = byte(tx_context.block_number)
    var dest = msg.destination
    discard ctx.evmcSetStorageImpl(dest, key, value)
    var output_data = alloc(output_size)
    var bn = $tx_context.block_number
    copyMem(output_data, bn[0].addr, bn.len)
    result.status_code = EVMC_SUCCESS
    result.gas_left = msg.gas div 2
    result.output_data = cast[ptr byte](output_data)
    result.output_size = output_size.uint
    result.release = evmcReleaseResultImpl
    return

  result.status_code = EVMC_FAILURE
  result.gas_left = 0

proc evmcGetCapabilitiesImpl(vm: ptr evmc_vm): evmc_capabilities_flagset {.cdecl.} =
  result.incl(EVMC_CAPABILITY_EVM1)
  result.incl(EVMC_CAPABILITY_EWASM)

proc evmcDestroyImpl(vm: ptr evmc_vm) {.cdecl.} =
  dealloc(vm)

proc init_host_interface(): evmc_host_interface =
  result.account_exists = cast[evmc_account_exists_fn](evmcAccountExistsImpl)
  result.get_storage = cast[evmc_get_storage_fn](evmcGetStorageImpl)
  result.set_storage = cast[evmc_set_storage_fn](evmcSetStorageImpl)
  result.get_balance = cast[evmc_get_balance_fn](evmcGetBalanceImpl)
  result.get_code_size = cast[evmc_get_code_size_fn](evmcGetCodeSizeImpl)
  result.get_code_hash = cast[evmc_get_code_hash_fn](evmcGetCodeHashImpl)
  result.copy_code = cast[evmc_copy_code_fn](evmcCopyCodeImpl)
  result.selfdestruct = cast[evmc_selfdestruct_fn](evmcSelfdestructImpl)
  result.call = cast[evmc_call_fn](evmcCallImpl)
  result.get_tx_context = cast[evmc_get_tx_context_fn](evmcGetTxContextImpl)
  result.get_block_hash = cast[evmc_get_block_hash_fn](evmcGetBlockHashImpl)
  result.emit_log = cast[evmc_emit_log_fn](evmcEmitLogImpl)

proc init(vm: ptr evmc_vm) {.exportc, cdecl.} =
  vm.destroy = evmcDestroyImpl
  vm.execute = cast[evmc_execute_fn](evmcExecuteImpl)
  vm.get_capabilities = evmcGetCapabilitiesImpl
  vm.set_option = evmcSetOptionImpl

let gHost = init_host_interface()
proc nim_host_get_interface*(): ptr evmc_host_interface {.exportc, cdecl.} =
  result = gHost.unsafeAddr

proc nim_host_create_context*(tx_context: evmc_tx_context): HostContext {.exportc, cdecl.} =
  result = HostContext(tx_context: tx_context)
  GC_ref(result)

proc nim_host_destroy_context*(ctx: HostContext) {.exportc, cdecl.} =
  GC_unref(ctx)

proc nim_create_example_vm*(): ptr evmc_vm {.exportc, cdecl.} =
  result = cast[ptr evmc_vm](new(evmc_vm))
  copyMem(result, globalVM.addr, sizeof(globalVM))
  init(result)

