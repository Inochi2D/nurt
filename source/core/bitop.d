/**
    NuRT Bit Operations Module.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Luna Nielsen
*/
module core.bitop;
import numem.core.math;

public:
nothrow:
@safe:
@nogc:

/**
    Scans the bits in the provided value from the most
    significant bit to the least significant bit, getting
    the offset of the first set bit.

    Params:
        value = The value to scan
    
    Returns:
        The index of the first bit set, value is undefined
        if value is zero.
*/
alias bsr = nu_bsr;

/**
    Scans the bits in the provided value from the least
    significant bit to the most significant bit, getting
    the offset of the first set bit.

    Params:
        value = The value to scan
    
    Returns:
        The index of the first bit set, value is undefined
        if value is zero.
*/
alias bsf = nu_bsf;