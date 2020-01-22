type
  evmc_bytes32* {.importc: "evmc_bytes32", header: "evmc/evmc.h", bycopy.} = object
    bytes* {.importc: "bytes".}: array[32, uint8]
  evmc_uint256be* = evmc_bytes32
  evmc_address* {.importc: "evmc_address", header: "evmc/evmc.h", bycopy.} = object
    bytes* {.importc: "bytes".}: array[20, uint8]
  evmc_call_kind* {.size: sizeof(cint).} = enum
    EVMC_CALL = 0, EVMC_DELEGATECALL = 1, EVMC_CALLCODE = 2, EVMC_CREATE = 3,
    EVMC_CREATE2 = 4
  evmc_flags* {.size: sizeof(cint).} = enum
    EVMC_STATIC = 1
  evmc_message* {.importc: "struct evmc_message", header: "evmc/evmc.h", bycopy.} = object
    kind* {.importc: "kind".}: evmc_call_kind
    flags* {.importc: "flags".}: uint32
    depth* {.importc: "depth".}: int32
    gas* {.importc: "gas".}: int64
    destination* {.importc: "destination".}: evmc_address
    sender* {.importc: "sender".}: evmc_address
    input_data* {.importc: "input_data".}: ptr uint8
    input_size* {.importc: "input_size".}: uint
    value* {.importc: "value".}: evmc_uint256be
    create2_salt* {.importc: "create2_salt".}: evmc_bytes32
  evmc_tx_context* {.importc: "struct evmc_tx_context", header: "evmc/evmc.h", bycopy.} = object
    tx_gas_price* {.importc: "tx_gas_price".}: evmc_uint256be
    tx_origin* {.importc: "tx_origin".}: evmc_address
    block_coinbase* {.importc: "block_coinbase".}: evmc_address
    block_number* {.importc: "block_number".}: int64
    block_timestamp* {.importc: "block_timestamp".}: int64
    block_gas_limit* {.importc: "block_gas_limit".}: int64
    block_difficulty* {.importc: "block_difficulty".}: evmc_uint256be
    chain_id* {.importc: "chain_id".}: evmc_uint256be
  evmc_host_context* {.importc: "struct evmc_host_context", header: "evmc/evmc.h", bycopy.} = object
  evmc_get_tx_context_fn* = proc (context: ptr evmc_host_context): evmc_tx_context {.
      cdecl.}
  evmc_get_block_hash_fn* = proc (context: ptr evmc_host_context; number: int64): evmc_bytes32 {.
      cdecl.}
  evmc_status_code* {.size: sizeof(cint).} = enum
    EVMC_OUT_OF_MEMORY = -3, EVMC_REJECTED = -2, EVMC_INTERNAL_ERROR = -1,
    EVMC_SUCCESS = 0, EVMC_FAILURE = 1, EVMC_REVERT = 2, EVMC_OUT_OF_GAS = 3,
    EVMC_INVALID_INSTRUCTION = 4, EVMC_UNDEFINED_INSTRUCTION = 5,
    EVMC_STACK_OVERFLOW = 6, EVMC_STACK_UNDERFLOW = 7, EVMC_BAD_JUMP_DESTINATION = 8,
    EVMC_INVALID_MEMORY_ACCESS = 9, EVMC_CALL_DEPTH_EXCEEDED = 10,
    EVMC_STATIC_MODE_VIOLATION = 11, EVMC_PRECOMPILE_FAILURE = 12,
    EVMC_CONTRACT_VALIDATION_FAILURE = 13, EVMC_ARGUMENT_OUT_OF_RANGE = 14,
    EVMC_WASM_UNREACHABLE_INSTRUCTION = 15, EVMC_WASM_TRAP = 16
  evmc_release_result_fn* = proc (result: ptr evmc_result) {.cdecl.}
  evmc_result* {.importc: "struct evmc_result", header: "evmc/evmc.h", bycopy.} = object
    status_code* {.importc: "status_code".}: evmc_status_code
    gas_left* {.importc: "gas_left".}: int64
    output_data* {.importc: "output_data".}: ptr uint8
    output_size* {.importc: "output_size".}: uint
    release* {.importc: "release".}: evmc_release_result_fn
    create_address* {.importc: "create_address".}: evmc_address
    padding* {.importc: "padding".}: array[4, uint8]
  evmc_account_exists_fn* = proc (context: ptr evmc_host_context;
                               address: ptr evmc_address): bool {.cdecl.}
  evmc_get_storage_fn* = proc (context: ptr evmc_host_context;
                            address: ptr evmc_address; key: ptr evmc_bytes32): evmc_bytes32 {.
      cdecl.}
  evmc_storage_status* {.size: sizeof(cint).} = enum
    EVMC_STORAGE_UNCHANGED = 0, EVMC_STORAGE_MODIFIED = 1,
    EVMC_STORAGE_MODIFIED_AGAIN = 2, EVMC_STORAGE_ADDED = 3, EVMC_STORAGE_DELETED = 4
  evmc_set_storage_fn* = proc (context: ptr evmc_host_context;
                            address: ptr evmc_address; key: ptr evmc_bytes32;
                            value: ptr evmc_bytes32): evmc_storage_status {.cdecl.}
  evmc_get_balance_fn* = proc (context: ptr evmc_host_context;
                            address: ptr evmc_address): evmc_uint256be {.cdecl.}
  evmc_get_code_size_fn* = proc (context: ptr evmc_host_context;
                              address: ptr evmc_address): uint {.cdecl.}
  evmc_get_code_hash_fn* = proc (context: ptr evmc_host_context;
                              address: ptr evmc_address): evmc_bytes32 {.cdecl.}
  evmc_copy_code_fn* = proc (context: ptr evmc_host_context;
                          address: ptr evmc_address; code_offset: uint;
                          buffer_data: ptr uint8; buffer_size: uint): uint {.cdecl.}
  evmc_selfdestruct_fn* = proc (context: ptr evmc_host_context;
                             address: ptr evmc_address;
                             beneficiary: ptr evmc_address) {.cdecl.}
  evmc_emit_log_fn* = proc (context: ptr evmc_host_context; address: ptr evmc_address;
                         data: ptr uint8; data_size: uint;
                         topics: ptr evmc_bytes32; topics_count: uint) {.cdecl.}
  evmc_call_fn* = proc (context: ptr evmc_host_context; msg: ptr evmc_message): evmc_result {.
      cdecl.}
  evmc_host_interface* {.importc: "struct evmc_host_interface", header: "evmc/evmc.h",
                        bycopy.} = object
    account_exists* {.importc: "account_exists".}: evmc_account_exists_fn
    get_storage* {.importc: "get_storage".}: evmc_get_storage_fn
    set_storage* {.importc: "set_storage".}: evmc_set_storage_fn
    get_balance* {.importc: "get_balance".}: evmc_get_balance_fn
    get_code_size* {.importc: "get_code_size".}: evmc_get_code_size_fn
    get_code_hash* {.importc: "get_code_hash".}: evmc_get_code_hash_fn
    copy_code* {.importc: "copy_code".}: evmc_copy_code_fn
    selfdestruct* {.importc: "selfdestruct".}: evmc_selfdestruct_fn
    call* {.importc: "call".}: evmc_call_fn
    get_tx_context* {.importc: "get_tx_context".}: evmc_get_tx_context_fn
    get_block_hash* {.importc: "get_block_hash".}: evmc_get_block_hash_fn
    emit_log* {.importc: "emit_log".}: evmc_emit_log_fn
  evmc_destroy_fn* = proc (vm: ptr evmc_vm) {.cdecl.}
  evmc_set_option_result* {.size: sizeof(cint).} = enum
    EVMC_SET_OPTION_SUCCESS = 0, EVMC_SET_OPTION_INVALID_NAME = 1,
    EVMC_SET_OPTION_INVALID_VALUE = 2
  evmc_set_option_fn* = proc (vm: ptr evmc_vm; name: cstring; value: cstring): evmc_set_option_result {.
      cdecl.}
  evmc_revision* {.size: sizeof(cint).} = enum
    EVMC_FRONTIER = 0, EVMC_HOMESTEAD = 1, EVMC_TANGERINE_WHISTLE = 2,
    EVMC_SPURIOUS_DRAGON = 3, EVMC_BYZANTIUM = 4, EVMC_CONSTANTINOPLE = 5,
    EVMC_PETERSBURG = 6, EVMC_ISTANBUL = 7, EVMC_BERLIN = 8
  evmc_execute_fn* = proc (vm: ptr evmc_vm; host: ptr evmc_host_interface;
                        context: ptr evmc_host_context; rev: evmc_revision;
                        msg: ptr evmc_message; code: ptr uint8; code_size: uint): evmc_result {.
      cdecl.}
  evmc_capabilities* {.size: sizeof(cint).} = enum
    EVMC_CAPABILITY_EVM1 = (1 shl 0), EVMC_CAPABILITY_EWASM = (1 shl 1),
    EVMC_CAPABILITY_PRECOMPILES = (1 shl 2)
  evmc_capabilities_flagset* = uint32
  evmc_get_capabilities_fn* = proc (vm: ptr evmc_vm): evmc_capabilities_flagset {.cdecl.}
  evmc_vm* {.importc: "struct evmc_vm", header: "evmc/evmc.h", bycopy.} = object
    abi_version* {.importc: "abi_version".}: cint
    name* {.importc: "name".}: cstring
    version* {.importc: "version".}: cstring
    destroy* {.importc: "destroy".}: evmc_destroy_fn
    execute* {.importc: "execute".}: evmc_execute_fn
    get_capabilities* {.importc: "get_capabilities".}: evmc_get_capabilities_fn
    set_option* {.importc: "set_option".}: evmc_set_option_fn

const
  EVMC_ABI_VERSION* = 7
  EVMC_MAX_REVISION* = EVMC_BERLIN
