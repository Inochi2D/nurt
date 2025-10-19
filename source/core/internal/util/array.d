/**
    Dynamic Array Support Hooks

    Copyright:
        Copyright © 2013-2025, Denis Shelomovskij 
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project

    License: Distributed under the
        $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
        (See accompanying file LICENSE)

    Authors:
        Denis Shelomovskij
        Luna Nielsen
*/
module core.internal.util.array;

@safe /* pure dmd @@@BUG11461@@@ */ nothrow:

/// Stub needed by some arrays.
void enforceRawArraysConformable(const char[] action, const size_t elementSize, const void[] a1, const void[] a2, const bool allowOverlap = false) { }

/// ditto
void enforceRawArraysConformableNogc(const char[] action, const size_t elementSize, const void[] a1, const void[] a2, const bool allowOverlap = false) @nogc { }