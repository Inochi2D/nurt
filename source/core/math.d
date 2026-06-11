/**
    NuRT Math Module.

    Copyright:
    	Copyright © 2012-2020, Digital Mars
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
    	$(HTTP digitalmars.com, Walter Bright),
		Don Clugston
        Luna Nielsen
*/
module core.math;
version(LDC) import ldc.intrinsics;

public @nogc nothrow @safe pure:

/***********************************
 * Returns cosine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cos(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN)) $(TD yes)     )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN)) $(TD yes)     )
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version (LDC)
{
    alias cos = llvm_cos!float;
    alias cos = llvm_cos!double;
    alias cos = llvm_cos!real;
}
else
{
    float cos(float x);     /* intrinsic */
    double cos(double x);   /* intrinsic */ /// ditto
    real cos(real x);       /* intrinsic */ /// ditto
}

/***********************************
 * Returns sine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)               $(TH sin(x))      $(TH invalid?))
 *      $(TR $(TD $(NAN))          $(TD $(NAN))      $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))    $(TD $(NAN))      $(TD yes))
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version (LDC)
{
    alias sin = llvm_sin!float;
    alias sin = llvm_sin!double;
    alias sin = llvm_sin!real;
}
else
{
    float sin(float x);     /* intrinsic */
    double sin(double x);   /* intrinsic */ /// ditto
    real sin(real x);       /* intrinsic */ /// ditto
}

/*****************************************
 * Returns x rounded to a long value using the current rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */

version (LDC)
{
    alias rndtol = llvm_llround!float;
    alias rndtol = llvm_llround!double;
    alias rndtol = llvm_llround!real;
}
else
{
    long rndtol(float x);   /* intrinsic */
    long rndtol(double x);  /* intrinsic */ /// ditto
    long rndtol(real x);    /* intrinsic */ /// ditto
}

/***************************************
 * Compute square root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH sqrt(x))   $(TH invalid?))
 *      $(TR $(TD -0.0)      $(TD -0.0)      $(TD no))
 *      $(TR $(TD $(LT)0.0)  $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */

version (LDC)
{
    pragma(inline, true):

    // http://llvm.org/docs/LangRef.html#llvm-sqrt-intrinsic
    // sqrt(x) when x is less than zero is undefined
    float  sqrt(float  x) { return x < 0 ? float.nan  : llvm_sqrt(x); }
    double sqrt(double x) { return x < 0 ? double.nan : llvm_sqrt(x); }
    real   sqrt(real   x) { return x < 0 ? real.nan   : llvm_sqrt(x); }
}
else
{
    float sqrt(float x);    /* intrinsic */
    double sqrt(double x);  /* intrinsic */ /// ditto
    real sqrt(real x);      /* intrinsic */ /// ditto
}
