module rt.deh.dwarf;
extern(C) export:

version(Windows) {
    void* _d_eh_enter_catch(void*, void*) {
        return null;
    }
} else {
    void* _d_eh_enter_catch(void*) {
        return null;
    }
}


enum _Unwind_State {
    VIRTUAL_UNWIND_FRAME = 0,
    UNWIND_FRAME_STARTING = 1,
    UNWIND_FRAME_RESUME = 2,
    ACTION_MASK = 3,
    FORCE_UNWIND = 8,
    END_OF_STACK = 16
}

extern(C) int _d_eh_personality(_Unwind_State,void*,void*) {
    return 0;
}