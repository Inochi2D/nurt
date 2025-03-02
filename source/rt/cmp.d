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

extern(C)
int _adEq2(void[] a1, void[] a2, TypeInfo ti) {

    if (a1.length != a2.length)
        return 0; // not equal
    if (!ti.equals(&a1, &a2))
        return 0;
    
    return 1;
}

int __cmp(T)(scope const T[] lhs, scope const T[] rhs) @trusted pure @nogc nothrow
        if (__traits(isScalar, T)) {
    // Compute U as the implementation type for T
    static if (is(T == ubyte) || is(T == void) || is(T == bool))
        alias U = char;
    else static if (is(T == wchar))
        alias U = ushort;
    else static if (is(T == dchar))
        alias U = uint;
    else static if (is(T == ifloat))
        alias U = float;
    else static if (is(T == idouble))
        alias U = double;
    else static if (is(T == ireal))
        alias U = real;
    else
        alias U = T;

    static if (is(U == char)) {
        int dstrcmp(scope const char[] s1, scope const char[] s2) @trusted pure @nogc nothrow {
            immutable len = s1.length <= s2.length ? s1.length : s2.length;
            if (__ctfe) {
                foreach (const u; 0 .. len) {
                    if (s1[u] != s2[u])
                        return s1[u] > s2[u] ? 1 : -1;
                }
            } else {
                const ret = memcmp(s1.ptr, s2.ptr, len);
                if (ret)
                    return ret;
            }
            return (s1.length > s2.length) - (s1.length < s2.length);
        }

        return dstrcmp(cast(char[]) lhs, cast(char[]) rhs);
    } else static if (!is(U == T)) {
        // Reuse another implementation
        return __cmp(cast(U[]) lhs, cast(U[]) rhs);
    } else {
        version (BigEndian)
            static if (__traits(isUnsigned, T) ? !is(T == __vector) :  is(T : P*, P)) {
                if (!__ctfe) {
                    import core.stdc.string : memcmp;

                    int c = memcmp(lhs.ptr, rhs.ptr, (lhs.length <= rhs.length ? lhs.length
                            : rhs.length) * T.sizeof);
                    if (c)
                        return c;
                    static if (size_t.sizeof <= uint.sizeof && T.sizeof >= 2)
                        return cast(int) lhs.length - cast(int) rhs.length;
                    else
                        return int(lhs.length > rhs.length) - int(lhs.length < rhs.length);
                }
            }

        immutable len = lhs.length <= rhs.length ? lhs.length : rhs.length;
        foreach (const u; 0 .. len) {
            auto a = lhs.ptr[u], b = rhs.ptr[u];
            static if (is(T : creal)) {
                // Use rt.cmath2._Ccmp instead ?
                // Also: if NaN is present, numbers will appear equal.
                auto r = (a.re > b.re) - (a.re < b.re);
                if (!r)
                    r = (a.im > b.im) - (a.im < b.im);
            } else {
                // This pattern for three-way comparison is better than conditional operators
                // See e.g. https://godbolt.org/z/3j4vh1
                const r = (a > b) - (a < b);
            }
            if (r)
                return r;
        }
        return (lhs.length > rhs.length) - (lhs.length < rhs.length);
    }
}

// This function is called by the compiler when dealing with array
// comparisons in the semantic analysis phase of CmpExp. The ordering
// comparison is lowered to a call to this template.
int __cmp(T1, T2)(T1[] s1, T2[] s2)
        if (!__traits(isScalar, T1) && !__traits(isScalar, T2)) {
    import core.internal.traits : Unqual;

    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static if (is(U1 == void) && is(U2 == void))
        static @trusted ref inout(ubyte) at(inout(void)[] r, size_t i) {
            return (cast(inout(ubyte)*) r.ptr)[i];
        }
    else
        static @trusted ref R at(R)(R[] r, size_t i) {
            return r.ptr[i];
        }

    // All unsigned byte-wide types = > dstrcmp
    immutable len = s1.length <= s2.length ? s1.length : s2.length;

    foreach (const u; 0 .. len) {
        static if (__traits(compiles, __cmp(at(s1, u), at(s2, u)))) {
            auto c = __cmp(at(s1, u), at(s2, u));
            if (c != 0)
                return c;
        } else static if (__traits(compiles, at(s1, u).opCmp(at(s2, u)))) {
            auto c = at(s1, u).opCmp(at(s2, u));
            if (c != 0)
                return c;
        } else static if (__traits(compiles, at(s1, u) < at(s2, u))) {
            if (int result = (at(s1, u) > at(s2, u)) - (at(s1, u) < at(s2, u)))
                return result;
        } else {
            // TODO: fix this legacy bad behavior, see
            // https://issues.dlang.org/show_bug.cgi?id=17244
            static assert(is(U1 == U2), "Internal error.");
            import core.stdc.string : memcmp;

            auto c = (() @trusted => memcmp(&at(s1, u), &at(s2, u), U1.sizeof))();
            if (c != 0)
                return c;
        }
    }
    return (s1.length > s2.length) - (s1.length < s2.length);
}