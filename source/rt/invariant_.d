/**
    Implementation of invariant support routines.

    Copyright:
        Copyright © Digital Mars, 2000-2025.
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Walter Bright, 
        Luna Nielsen
*/
module rt.invariant_;

/* */
pragma(mangle, "_D9invariant12_d_invariantFC6ObjectZv")
export
void _d_invariant(Object o) {
    ClassInfo c;

    //printf("__d_invariant(%p)\n", o);

    // BUG: needs to be filename/line of caller, not library routine
    assert(o !is null); // just do null check, not invariant check

    c = typeid(o);
    do
    {
        if (c.classInvariant)
        {
            (*c.classInvariant)(o);
        }
        c = c.base;
    } while (c);
}