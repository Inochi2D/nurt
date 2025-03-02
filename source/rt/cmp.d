/**
    Implementation of comparison runtime hooks.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module rt.cmp;
@nogc nothrow:

extern(C)
bool __equals(T1, T2)(scope const T1[] lhs, scope const T2[] rhs) {
    if (lhs.length != rhs.length) {
        return false;
    }
    foreach(i; 0..lhs.length) {
        if (lhs[i] != rhs[i]) {
            return false;
        }
    }
    return true;
}