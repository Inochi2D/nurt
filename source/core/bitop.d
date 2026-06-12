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


pragma(inline, true) // LDC
int bt(const scope size_t* p, size_t bitnum) pure @system
{
    static if (size_t.sizeof == 8)
        return ((p[bitnum >> 6] & (1L << (bitnum & 63)))) != 0;
    else static if (size_t.sizeof == 4)
        return ((p[bitnum >> 5] & (1  << (bitnum & 31)))) != 0;
    else
        static assert(0);
}

version (LDC)
{
    pragma(LDC_intrinsic, "ldc.bitop.bts")
        private int __bts(size_t* p, size_t bitnum) pure @system;
    pragma(LDC_intrinsic, "ldc.bitop.btc")
        private int __btc(size_t* p, size_t bitnum) pure @system;
    pragma(LDC_intrinsic, "ldc.bitop.btr")
        private int __btr(size_t* p, size_t bitnum) pure @system;
}

private
int softBtx(string op)(size_t* p, size_t bitnum) pure @system
{
    size_t indexIntoArray = bitnum / (size_t.sizeof*8);
    size_t bitmask = size_t(1) << (bitnum & ((size_t.sizeof*8) - 1));
    size_t original = p[indexIntoArray];
    mixin("p[indexIntoArray] = original " ~ op ~ " bitmask;");
    return (original&bitmask) > 0 ? true : false;
}
/**
 * Tests and complements the bit.
 */
pragma(inline, true) // LDC
int btc(size_t* p, size_t bitnum) pure @system
{
    version (LDC)
    {
        if (!__ctfe)
            return __btc(p, bitnum);
    }
    else
    {
        pragma(inline, false);  // such that DMD intrinsic detection will work
    }
    return softBtx!"^"(p, bitnum);
}


/**
 * Tests and resets (sets to 0) the bit.
 */
pragma(inline, true) // LDC
int btr(size_t* p, size_t bitnum) pure @system
{
    version (LDC)
    {
        if (!__ctfe)
            return __btr(p, bitnum);
    }
    else
    {
        pragma(inline, false);  // such that DMD intrinsic detection will work
    }
    return softBtx!"& ~"(p, bitnum);
}


/**
 * Tests and sets the bit.
 * Params:
 * p = a non-NULL pointer to an array of size_ts.
 * bitnum = a bit number, starting with bit 0 of p[0],
 * and progressing. It addresses bits like the expression:
---
p[index / (size_t.sizeof*8)] & (1 << (index & ((size_t.sizeof*8) - 1)))
---
 * Returns:
 *      A non-zero value if the bit was set, and a zero
 *      if it was clear.
 */
pragma(inline, true) // LDC
int bts(size_t* p, size_t bitnum) pure @system
{
    version (LDC)
    {
        if (!__ctfe)
            return __bts(p, bitnum);
    }
    else
    {
        pragma(inline, false);  // such that DMD intrinsic detection will work
    }
    return softBtx!"|"(p, bitnum);
}