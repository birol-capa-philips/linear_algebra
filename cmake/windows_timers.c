#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

#include "f2c.h"

static INIT_ONCE timer_once = INIT_ONCE_STATIC_INIT;
static LARGE_INTEGER timer_frequency;
static LARGE_INTEGER timer_origin;

static BOOL CALLBACK initialize_timer(
    PINIT_ONCE init_once, PVOID parameter, PVOID *context)
{
    UNREFERENCED_PARAMETER(init_once);
    UNREFERENCED_PARAMETER(parameter);
    UNREFERENCED_PARAMETER(context);

    return QueryPerformanceFrequency(&timer_frequency) &&
        QueryPerformanceCounter(&timer_origin);
}

static doublereal elapsed_seconds(void)
{
    LARGE_INTEGER counter;

    if (!InitOnceExecuteOnce(&timer_once, initialize_timer, NULL, NULL) ||
        !QueryPerformanceCounter(&counter)) {
        return 0.0;
    }

    return (doublereal)(counter.QuadPart - timer_origin.QuadPart) /
        (doublereal)timer_frequency.QuadPart;
}

doublereal second_(void)
{
    return elapsed_seconds();
}

doublereal dsecnd_(void)
{
    return elapsed_seconds();
}