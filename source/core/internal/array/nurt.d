/**
    Dynamic Array Support Hooks

    Copyright:
        Copyright © 2000-2025, Digital Mars 
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        DLang Contributors
        Luna Nielsen
*/
module core.internal.array.nurt;
import numem.core.meta : Filter, staticMap;
import numem.core.traits;
import numem.core.hooks;
import rt.lifetime;
import numem;

/**
    Extend an array `px` by `n` elements.
    Caller must initialize those elements.

    Params:
        px = the array that will be extended, taken as a reference
        n = how many new elements to extend it with

    Returns:
        The new value of `px`

    Bugs:
        This function template was ported from a much older runtime hook that bypassed safety,
        purity, and throwabilty checks. To prevent breaking existing code, this function template
        is temporarily declared `@trusted` until the implementation can be brought up to modern D expectations.
*/
ref Tarr _d_arrayappendcTX(Tarr : T[], T)(return ref scope Tarr px, size_t n) @nogc nothrow pure {
    alias Unqual_T = Unqual!T;
    alias Unqual_Tarr = Unqual_T[];
    enum isshared = is(T == shared);
    auto unqual_px = cast(Unqual_Tarr) px;

    // Ignoring additional attributes allows reusing the same generated code
    px = cast(Tarr) _d_arrayappendcTX_(unqual_px, n, isshared);
    return px;
}

/**
    Resize a dynamic array by setting its `.length` property.

    Newly created elements are initialized based on their default value.
    If the array's elements initialize to `0`, memory is zeroed out. Otherwise, elements are explicitly initialized.

    This function handles memory allocation, expansion, and initialization while maintaining array integrity.

    ---
    void main()
    {
        int[] a = [1, 2];
        a.length = 3; // Gets lowered to `_d_arraysetlengthT!(int)(a, 3, false)`
    }
    ---

    Params:
        arr         = The array to resize.
        newlength   = The new value for the array's `.length`.

    Returns:
        The resized array with updated length and properly initialized elements.

    Throws:
        OutOfMemoryError if allocation fails.
*/
size_t _d_arraysetlengthT(Tarr : T[], T)(return ref scope Tarr arr, size_t newlength) @nogc nothrow @trusted {

    // Check if the type is shared
    enum isShared = is(T == shared);

    // Unqualify the type to remove `const`, `immutable`, `shared`, etc.
    alias UnqT = Unqual!T;

    // Cast the array to the unqualified type
    auto unqual_arr = cast(UnqT[]) arr;

    // Call the implementation with the unqualified array and sharedness flag
    size_t result = _d_arraysetlengthT_(unqual_arr, newlength, isShared);

    arr = cast(Tarr) unqual_arr;

    // Return the result
    return result;
}

/**
    The compiler lowers expressions of `cast(TTo[])TFrom[]` to
    this implementation. Note that this does not detect alignment problems.

    Params:
        from = the array to reinterpret-cast

    Returns:
        `from` reinterpreted as `TTo[]`
*/
TTo[] __ArrayCast(TFrom, TTo)(return scope TFrom[] from) @nogc nothrow @trusted pure {
    const fromSize = from.length * TFrom.sizeof;
    const toLength = fromSize / TTo.sizeof;

    if ((fromSize % TTo.sizeof) != 0) {
        nu_fatal("Failed to reinterpret-cast array, sizes mismatched.");
    }

    struct Array {
        size_t length;
        void* ptr;
    }

    auto a = cast(Array*)&from;
    a.length = toLength; // jam new length
    return *cast(TTo[]*) a;
}

/**
    Concatenate the arrays inside of `froms`.
    `_d_arraycatnTX(a, b, c)` means `a ~ b ~ c`.

    Params:
       froms = Arrays to be concatenated.
    Returns:
       A newly allocated array that contains all the elements from `froms`.
*/
Tret _d_arraycatnTX(Tret, Tarr...)(auto ref Tarr froms) @nogc nothrow @trusted {
    if (__ctfe) {
        Tret res;
        static foreach (from; froms)
            res ~= from;

        return res;
    } else {

        Tret res;
        size_t totalLen;

        alias T = typeof(res[0]); // Element type of the result array
        alias UnqT = Unqual!T; // Unqualified version of T (strips const/immutable)
        enum elemSize = T.sizeof; // Size of each element
        enum hasPostblit = __traits(hasPostblit, T); // Whether T has a postblit constructor

        // Compute total length of the resulting array
        static foreach (from; froms)
            static if (is(typeof(from) : T))
                totalLen++; // Single element contributes one to length
            else
                totalLen += from.length; // Arrays contribute their full length

        if (totalLen == 0)
            return res; // Return an empty array if no elements are present

        res = nu_malloca!T(totalLen);
        auto resptr = cast(UnqT*) res.ptr;
        foreach (ref from; froms)
            static if (is(typeof(from) : T))
                nu_memcpy(resptr++, cast(UnqT*)&from, elemSize);
            else {
                const len = from.length;
                if (len) {
                    nu_memcpy(resptr, cast(UnqT*) from, len * elemSize);
                    resptr += len;
                }
            }

        static if (hasPostblit)
            foreach (ref elem; res)
                (cast() elem).__xpostblit();

        return res;
    }
}

/**
    Perform array (vector) operations and store the result in `res`.  Operand
    types and operations are passed as template arguments in Reverse Polish
    Notation (RPN).
    Operands can be slices or scalar types. The element types of all
    slices and all scalar types must be implicitly convertible to `T`.

    Operations are encoded as strings, e.g. `"+"`, `"%"`, `"*="`. Unary
    operations are prefixed with "u", e.g. `"u-"`, `"u~"`. Only the last
    operation can and must be an assignment (`"="`) or op-assignment (`"op="`).

    All slice operands must have the same length as the result slice.

    Params:
        T[] = type of result slice
        Args = operand types and operations in RPN
        res = the slice in which to store the results
        args = operand values

    Returns:
        The slice containing the result
*/
T[] arrayOp(T : T[], Args...)(T[] res, Filter!(isType, Args) args) @trusted @nogc nothrow {
    alias scalarizedExp = staticMap!(toElementType, Args);
    alias check = typeCheck!(true, T, scalarizedExp); // must support all scalar ops

    foreach (argsIdx, arg; typeof(args)) {
        static if (is(arg == U[], U)) {
            assert(res.length == args[argsIdx].length, "Mismatched array lengths for vector operation");
        }
    }

    size_t pos;
    static if (vectorizeable!(T[], Args)) {
        alias vec = .vec!T;
        alias load = .load!(T, vec.length);
        alias store = .store!(T, vec.length);

        // Given that there are at most as many scalars broadcast as there are
        // operations in any `ary[] = ary[] op const op const`, it should always be
        // worthwhile to choose vector operations.
        if (!__ctfe && res.length >= vec.length) {
            mixin(initScalarVecs!Args);

            auto n = res.length / vec.length;
            do {
                mixin(vectorExp!Args ~ ";");
                pos += vec.length;
            }
            while (--n);
        }
    }
    for (; pos < res.length; ++pos)
        mixin(scalarExp!Args ~ ";");

    return res;
}

template _arrayOp(Args...) {
    alias _arrayOp = arrayOp!Args;
}

/// ditto
T[] _d_newarrayT(T)(size_t length, bool isShared = false) @trusted {
    T[] result = nu_malloca!T(length);
    return result;
}

U[] _dup(T, U)(T[] a) @trusted {
    if (__ctfe)
        return _dupCtfe!(T, U)(a);

    version (D_BetterC)
        return _dupCtfe!(T, U)(a);

    return cast(U[]) a.nu_dup();
}

/// Implementation of `_d_arrayappendT`
ref Tarr _d_arrayappendT(Tarr : T[], T)(return ref scope Tarr x, scope Tarr y) @trusted {
    version (DigitalMars) pragma(inline, false);

    if (__ctfe) {
        import core.stdc.string : memcpy;
        import core.internal.traits : hasElaborateCopyConstructor, Unqual;

        enum hasPostblit = __traits(hasPostblit, T);
        auto length = x.length;

        _d_arrayappendcTX(x, y.length);

        // Only call `copyEmplace` if `T` has a copy ctor and no postblit.
        static if (hasElaborateCopyConstructor!T && !hasPostblit) {
            import core.lifetime : copyEmplace;

            foreach (i, ref elem; y)
                copyEmplace(elem, x[length + i]);
        } else {
            if (y.length) {
                // blit all elements at once
                auto xptr = cast(Unqual!T*)&x[length];
                immutable size = T.sizeof;

                memcpy(xptr, cast(Unqual!T*)&y[0], y.length * size);

                // call postblits if they exist
                static if (hasPostblit) {
                    auto eptr = xptr + y.length;
                    for (auto ptr = xptr; ptr < eptr; ptr++)
                        ptr.__xpostblit();
                }
            }
        }

        return x;
    } else {

        size_t start = x.length;
        x = x.nu_resize(x.length + y.length);
        nu_memcpy(cast(void*)&x[start], cast(void*) y.ptr, y.length * T.sizeof);
        return x;
    }
}

// Pre-array templatification helpers.
static if (__VERSION__ <= 2111) {
    template _d_arraysetlengthTImpl(Tarr : T[], T) {
        private enum errorMessage = "Cannot resize arrays if compiling without support for runtime type information!";
        size_t _d_arraysetlengthT(return scope ref Tarr arr, size_t newlength) @trusted nothrow {
            version (DigitalMars) pragma(inline, false);
            return _d_arraysetlengthT_(arr, newlength, is(T == shared));
        }
    }
}

//
//          IMPLEMENTATION DETAILS.
//
private:

/// Implementation of `_d_arrayappendcTX`
ref Tarr _d_arrayappendcTX_(Tarr : T[], T)(return ref scope Tarr px, size_t n, bool isshared) @trusted pure {
    version (DigitalMars) pragma(inline, false);
    version (D_TypeInfo) {

        // Short circuit if no data is being appended.
        if (n == 0)
            return px;

        if (__ctfe) {

            px.length = px.length + n;
            return px;
        } else {

            enum sizeelem = T.sizeof;
            auto newlength = px.length + n;
            auto newsize = newlength * sizeelem;
            return px.nu_resize(newsize);
        }
    } else
        assert(0, "Cannot append to array if compiling without support for runtime type information!");
}

/// Implementation of `_d_arraysetlengthT`
size_t _d_arraysetlengthT_(Tarr : T[], T)(return ref scope Tarr arr, size_t newlength, bool isShared) @trusted nothrow {
    if (__ctfe) {

        arr.length = newlength;
        return newlength;
    } else {

        // If the new length is less than or equal to the current length, just truncate the array
        if (newlength <= arr.length) {
            arr = arr[0 .. newlength];
            return newlength;
        }

        // Otherwise use numem primitives.
        size_t oldlength = arr.length;
        arr = arr.nu_resize(newlength);
        nogc_initialize(arr[oldlength .. newlength]);
        return newlength;
    }
}

// CTFE .dup function
U[] _dupCtfe(T, U)(scope T[] a) @trusted nothrow {
    version (DigitalMars) pragma(inline, false);

    if (__ctfe) {
        static if (is(T : void))
            assert(0, "Cannot dup a void[] array at compile time.");
        else {
            U[] res;
            foreach (ref e; a)
                res ~= e;
            return res;
        }
    } else {
        return cast(U[]) a;
    }
}

enum isCopyingNothrow(T) = __traits(compiles, (ref T rhs) nothrow{ T lhs = rhs; });

// SIMD helpers

version (DigitalMars) {
    import core.simd;

    template vec(T) {
        enum regsz = 16; // SSE2
        enum N = regsz / T.sizeof;
        alias vec = __vector(T[N]);
    }

    void store(T, size_t N)(T* p, const scope __vector(T[N]) val) {
        pragma(inline, true);
        alias vec = __vector(T[N]);

        static if (is(T == float))
            cast(void) __simd_sto(XMM.STOUPS, *cast(vec*) p, val);
        else static if (is(T == double))
            cast(void) __simd_sto(XMM.STOUPD, *cast(vec*) p, val);
        else
            cast(void) __simd_sto(XMM.STODQU, *cast(vec*) p, val);
    }

    const(__vector(T[N])) load(T, size_t N)(const scope T* p) {
        import core.simd;

        pragma(inline, true);
        alias vec = __vector(T[N]);

        static if (is(T == float))
            return cast(typeof(return)) __simd(XMM.LODUPS, *cast(const vec*) p);
        else static if (is(T == double))
            return cast(typeof(return)) __simd(XMM.LODUPD, *cast(const vec*) p);
        else
            return cast(typeof(return)) __simd(XMM.LODDQU, *cast(const vec*) p);
    }

    __vector(T[N]) binop(string op, T, size_t N)(const scope __vector(T[N]) a, const scope __vector(
            T[N]) b) {
        pragma(inline, true);
        return mixin("a " ~ op ~ " b");
    }

    __vector(T[N]) unaop(string op, T, size_t N)(const scope __vector(T[N]) a)
            if (op[0] == 'u') {
        pragma(inline, true);
        return mixin(op[1 .. $] ~ "a");
    }
}
// mixin gen

/**
    Check whether operations on operand types are supported.  This
    template recursively reduces the expression tree and determines
    intermediate types.
    Type checking is done here rather than in the compiler to provide more
    detailed error messages.

    Params:
        fail = whether to fail (static assert) with a human-friendly error message
        T = type of result
        Args = operand types and operations in RPN
    Returns:
        The resulting type of the expression
    See_Also:
        $(LREF arrayOp)
*/
template typeCheck(bool fail, T, Args...) {
    enum idx = staticIndexOf!(not!isType, Args);
    static if (isUnaryOp(Args[idx])) {
        alias UT = Args[idx - 1];
        enum op = Args[idx][1 .. $];
        static if (is(typeof((UT a) => mixin(op ~ "cast(int) a")) RT == return))
            alias typeCheck = typeCheck!(fail, T, Args[0 .. idx - 1], RT, Args[idx + 1 .. $]);
        else static if (fail)
            static assert(0, "Unary `" ~ op ~ "` not supported for type `" ~ UT.stringof ~ "`.");
    } else static if (isBinaryOp(Args[idx])) {
        alias LHT = Args[idx - 2];
        alias RHT = Args[idx - 1];
        enum op = Args[idx];
        static if (is(typeof((LHT a, RHT b) => mixin("a " ~ op ~ " b")) RT == return))
            alias typeCheck = typeCheck!(fail, T, Args[0 .. idx - 2], RT, Args[idx + 1 .. $]);
        else static if (fail)
            static assert(0,
                "Binary `" ~ op ~ "` not supported for types `"
                    ~ LHT.stringof ~ "` and `" ~ RHT.stringof ~ "`.");
    } else static if (Args[idx] == "=" || isBinaryAssignOp(Args[idx])) {
        alias RHT = Args[idx - 1];
        enum op = Args[idx];
        static if (is(T == __vector(ET[N]), ET, size_t N)) {
            // no `cast(T)` before assignment for vectors
            static if (is(typeof((T res, RHT b) => mixin("res " ~ op ~ " b")) RT == return)
                &&  // workaround https://issues.dlang.org/show_bug.cgi?id=17758
                (op != "=" || is(Unqual!T == Unqual!RHT)))
                alias typeCheck = typeCheck!(fail, T, Args[0 .. idx - 1], RT, Args[idx + 1 .. $]);
            else static if (fail)
                static assert(0,
                    "Binary op `" ~ op ~ "` not supported for types `"
                        ~ T.stringof ~ "` and `" ~ RHT.stringof ~ "`.");
        } else {
            static if (is(typeof((RHT b) => mixin("cast(T) b")))) {
                static if (is(typeof((T res, T b) => mixin("res " ~ op ~ " b")) RT == return))
                    alias typeCheck = typeCheck!(fail, T, Args[0 .. idx - 1], RT, Args[idx + 1 .. $]);
                else static if (fail)
                    static assert(0,
                        "Binary op `" ~ op ~ "` not supported for types `"
                            ~ T.stringof ~ "` and `" ~ T.stringof ~ "`.");
            } else static if (fail)
                static assert(0,
                    "`cast(" ~ T.stringof ~ ")` not supported for type `" ~ RHT.stringof ~ "`.");
        }
    } else
        static assert(0);
}
/// ditto
template typeCheck(bool fail, T, ResultType) {
    alias typeCheck = ResultType;
}

version (GNU_OR_LDC) {
    // leave it to the auto-vectorizer
    enum vectorizeable(E : E[], Args...) = false;
} else {
    // check whether arrayOp is vectorizable
    template vectorizeable(E : E[], Args...) {
        static if (is(vec!E)) {
            // type check with vector types
            enum vectorizeable = is(typeCheck!(false, vec!E, staticMap!(toVecType, Args)));
        } else
            enum vectorizeable = false;
    }

    version (X86_64) unittest {
        static assert(vectorizeable!(double[], const(double)[], double[], "+", "="));
        static assert(!vectorizeable!(double[], const(ulong)[], double[], "+", "="));
        // Vector type are (atm.) not implicitly convertible and would require
        // lots of SIMD intrinsics. Therefor leave mixed type array ops to
        // GDC/LDC's auto-vectorizers.
        static assert(!vectorizeable!(double[], const(uint)[], uint, "+", "="));
    }
}

bool isUnaryOp(scope string op) pure nothrow @safe @nogc {
    return op[0] == 'u';
}

bool isBinaryOp(scope string op) pure nothrow @safe @nogc {
    if (op == "^^")
        return true;
    if (op.length != 1)
        return false;
    switch (op[0]) {
    case '+', '-', '*', '/', '%', '|', '&', '^':
        return true;
    default:
        return false;
    }
}

bool isBinaryAssignOp(string op) {
    return op.length >= 2 && op[$ - 1] == '=' && isBinaryOp(op[0 .. $ - 1]);
}

// Generate mixin expression to perform scalar arrayOp loop expression, assumes
// `pos` to be the current slice index, `args` to contain operand values, and
// `res` the target slice.
enum scalarExp(Args...) =
    () {
    string[] stack;
    size_t argsIdx;

    static if (is(Args[0] == U[], U))
        alias Type = U;
    else
        alias Type = Args[0];

    foreach (i, arg; Args) {
        static if (is(arg == T[], T))
            stack ~= "args[" ~ argsIdx++.toString ~ "][pos]";
        else static if (is(arg))
            stack ~= "args[" ~ argsIdx++.toString ~ "]";
        else static if (isUnaryOp(arg)) {
            auto op = arg[0] == 'u' ? arg[1 .. $] : arg;
            // Explicitly use the old integral promotion rules
            // See also: https://dlang.org/changelog/2.078.0.html#fix16997
            static if (is(Type : int))
                stack[$ - 1] = "cast(typeof(" ~ stack[$ - 1] ~ "))" ~ op ~ "cast(int)(" ~ stack[$ - 1] ~ ")";
            else
                stack[$ - 1] = op ~ stack[$ - 1];
        } else static if (arg == "=") {
            stack[$ - 1] = "res[pos] = cast(T)(" ~ stack[$ - 1] ~ ")";
        } else static if (isBinaryAssignOp(arg)) {
            stack[$ - 1] = "res[pos] " ~ arg ~ " cast(T)(" ~ stack[$ - 1] ~ ")";
        } else static if (isBinaryOp(arg)) {
            stack[$ - 2] = "(" ~ stack[$ - 2] ~ " " ~ arg ~ " " ~ stack[$ - 1] ~ ")";
            stack.length -= 1;
        } else
            assert(0, "Unexpected op " ~ arg);
    }
    assert(stack.length == 1);
    return stack[0];
}();

// Generate mixin statement to perform vector loop initialization, assumes
// `args` to contain operand values.
enum initScalarVecs(Args...) =
    () {
    size_t scalarsIdx,
    argsIdx;
    string res;
    foreach (arg; Args) {
        static if (is(arg == T[], T)) {
            ++argsIdx;
        } else static if (is(arg))
            res ~= "immutable vec scalar" ~ scalarsIdx++.toString ~ " = args["
                ~ argsIdx++.toString ~ "];\n";
    }
    return res;
}();

// Generate mixin expression to perform vector arrayOp loop expression, assumes
// `pos` to be the current slice index, `args` to contain operand values, and
// `res` the target slice.
enum vectorExp(Args...) =
    () {
    size_t scalarsIdx,
    argsIdx;
    string[] stack;
    foreach (arg; Args) {
        static if (is(arg == T[], T))
            stack ~= "load(&args[" ~ argsIdx++.toString ~ "][pos])";
        else static if (is(arg)) {
            ++argsIdx;
            stack ~= "scalar" ~ scalarsIdx++.toString;
        } else static if (isUnaryOp(arg)) {
            auto op = arg[0] == 'u' ? arg[1 .. $] : arg;
            stack[$ - 1] = "unaop!\"" ~ arg ~ "\"(" ~ stack[$ - 1] ~ ")";
        } else static if (arg == "=") {
            stack[$ - 1] = "store(&res[pos], " ~ stack[$ - 1] ~ ")";
        } else static if (isBinaryAssignOp(arg)) {
            stack[$ - 1] = "store(&res[pos], binop!\"" ~ arg[0 .. $ - 1]
                ~ "\"(load(&res[pos]), " ~ stack[$ - 1] ~ "))";
        } else static if (isBinaryOp(arg)) {
            stack[$ - 2] = "binop!\"" ~ arg ~ "\"(" ~ stack[$ - 2] ~ ", " ~ stack[$ - 1] ~ ")";
            stack.length -= 1;
        } else
            assert(0, "Unexpected op " ~ arg);
    }
    assert(stack.length == 1);
    return stack[0];
}();

// other helpers

enum isType(T) = true;
enum isType(alias a) = false;
template not(alias tmlp) {
    enum not(Args...) = !tmlp!Args;
}
/**
Find element in `haystack` for which `pred` is true.

Params:
    pred = the template predicate
    haystack = elements to search
Returns:
    The first index for which `pred!haystack[index]` is true or -1.
 */
template staticIndexOf(alias pred, haystack...) {
    static if (pred!(haystack[0]))
        enum staticIndexOf = 0;
    else {
        enum next = staticIndexOf!(pred, haystack[1 .. $]);
        enum staticIndexOf = next == -1 ? -1 : next + 1;
    }
}
/// converts slice types to their element type, preserves anything else
alias toElementType(E : E[]) = E;
alias toElementType(S) = S;
alias toElementType(alias op) = op;
/// converts slice types to their element type, preserves anything else
alias toVecType(E : E[]) = vec!E;
alias toVecType(S) = vec!S;
alias toVecType(alias op) = op;

string toString(size_t num) {
    import core.internal.string : unsignedToTempString;

    // Workaround for https://issues.dlang.org/show_bug.cgi?id=19268
    if (__ctfe) {
        char[20] fixedbuf = void;
        char[] buf = unsignedToTempString(num, fixedbuf);
        char[] result = new char[buf.length];
        result[] = buf[];
        return (() @trusted => cast(string) result)();
    } else {
        // Failing at execution rather than during compilation is
        // not good, but this is in `core.internal` so it should
        // not be used by the unwary.
        assert(0, __FUNCTION__ ~ " not available in -betterC except during CTFE.");
    }
}

bool contains(T)(const scope T[] ary, const scope T[] vals...) {
    foreach (v1; ary)
        foreach (v2; vals)
            if (v1 == v2)
                return true;
    return false;
}
