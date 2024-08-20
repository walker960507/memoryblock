`define CORE_PARAM #( \
             parameter L1D_BANK_SIZE = 16,\
             parameter L1D_CACHELINE_SIZE = 64,\
             parameter PA_WIDTH     = 32,\
             parameter L1D_SIZE           = 32768,\
             parameter L1D_NUM_WAYS       = 2,\
             parameter L1D_TAG_STATE_WIDTH = 3,\
             parameter STB_NUM             = 1,\
             parameter REFILL_NUM          = 1,\
             parameter SNPSLV_NUM          = 1,\
             parameter INSTRUCTION_WIDTH   = 32,\
             parameter MEM_CACHE_ADDR_MIN  = 32'h80000000,\
             parameter MEM_CACHE_ADDR_MAX  = 32'h8fffffff,\
             parameter PARAM_END = 0)

`define REFILL_SLOT_PARAM #( \
             parameter ID            = 0,\
             parameter L1D_BANK_SIZE = 16,\
             parameter L1D_CACHELINE_SIZE = 64,\
             parameter PA_WIDTH           = 32,\
             parameter L1D_SIZE           = 32768,\
             parameter L1D_NUM_WAYS       = 2,\
             parameter L1D_TAG_STATE_WIDTH = 3,\
             parameter STB_NUM             = 1,\
             parameter REFILL_NUM          = 1,\
             parameter SNPSLV_NUM          = 1,\
             parameter INSTRUCTION_WIDTH   = 32,\
             parameter MEM_CACHE_ADDR_MIN  = 32'h80000000,\
             parameter MEM_CACHE_ADDR_MAX  = 32'h8fffffff,\
             parameter PARAM_END = 0)

 `define REFILL_SLOT_PARAM_INST  .L1D_BANK_SIZE(L1D_BANK_SIZE),\
                                 .L1D_CACHELINE_SIZE(L1D_CACHELINE_SIZE),\
                                 .PA_WIDTH(PA_WIDTH),\
                                 .L1D_SIZE(L1D_SIZE),\
                                 .L1D_NUM_WAYS(L1D_NUM_WAYS),\
                                 .L1D_TAG_STATE_WIDTH(L1D_TAG_STATE_WIDTH),\
                                 .STB_NUM(STB_NUM),\
                                 .REFILL_NUM(REFILL_NUM),\
                                 .SNPSLV_NUM(SNPSLV_NUM),\
                                 .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),\
                                 .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),\
                                 .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX),\
                                 .PARAM_END(1)
