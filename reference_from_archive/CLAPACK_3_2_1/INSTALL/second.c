#include <taskLib.h>
#include <tickLib.h>
#include "f2c.h"

/*
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>

#ifndef CLK_TCK
#define CLK_TCK 60
#endif
*/

doublereal second_()
{
  /* struct tms rusage; */

  /* times(&rusage); */
  /* return (doublereal)(rusage.tms_utime) / CLK_TCK; */

  /* This is approximate, assuming the test thread is utilizing 100% of the CPU: */
  return (doublereal)(tick64Get()/((unsigned long long)sysClkRateGet()));

} /* second_ */

