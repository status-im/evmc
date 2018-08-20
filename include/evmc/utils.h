/* EVMC: Ethereum Client-VM Connector API.
 * Copyright 2018 Pawel Bylica.
 * Licensed under the MIT License. See the LICENSE file.
 */

#pragma once

/**
 * @addtogroup helpers
 * @{
 */

/**
 * @def EVMC_EXPORT
 * Marks a function to be exported from a shared library.
 */
#if defined _MSC_VER || defined __MINGW32__
#define EVMC_EXPORT __declspec(dllexport)
#else
#define EVMC_EXPORT __attribute__((visibility("default")))
#endif

/**
 * @def EVMC_NOEXCEPT
 * Safe way of marking a function with `noexcept` C++ specifier.
 */
#if __cplusplus
#define EVMC_NOEXCEPT noexcept
#else
#define EVMC_NOEXCEPT
#endif

/** @} */