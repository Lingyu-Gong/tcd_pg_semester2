/* Include files */

#include "receiveBPSK_PLUTOSDR_cgxe.h"
#include "m_yO7Nb9BHgdQGUKVU9FwEjG.h"

unsigned int cgxe_receiveBPSK_PLUTOSDR_method_dispatcher(SimStruct* S, int_T
  method, void* data)
{
  if (ssGetChecksum0(S) == 2075772917 &&
      ssGetChecksum1(S) == 2351653504 &&
      ssGetChecksum2(S) == 4260884033 &&
      ssGetChecksum3(S) == 2028377526) {
    method_dispatcher_yO7Nb9BHgdQGUKVU9FwEjG(S, method, data);
    return 1;
  }

  return 0;
}
