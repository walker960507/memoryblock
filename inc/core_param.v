`define CORE_PARAM parameter L1D_BANK_SIZE = 16,\
				   parameter L1D_CACHELINE_SIZE = 64,\
				   parameter PA_WIDTH     = 32,\
				   parameter VA_WIDTH     = 32,\
				   parameter L1D_SIZE           = 32768,\
				   parameter L1D_NUM_WAYS       = 2,\
				   parameter STB_NUM		      = 1,\
				   parameter REFILL_NUM		  = 1,\
				   parameter SNPSLV_NUM		  = 1,\
				   parameter VICTIM_NUM		  = 1,\
				   parameter INSTRUCTION_WIDTH   = 32,\
				   parameter MEM_CACHE_ADDR_MIN  = 32'h80000000,\
				   parameter MEM_CACHE_ADDR_MAX  = 32'h8fffffff,\
				   parameter SUPPORT_MMU = 1,\
				   parameter ITLB_ENTRY_NUM = 1,\
				   parameter DTLB_ENTRY_NUM = 1,\
				   parameter PARAM_END = 0
`define CORE_PARAM_INST .L1D_BANK_SIZE(L1D_BANK_SIZE),\
						.L1D_CACHELINE_SIZE(L1D_CACHELINE_SIZE),\
						.PA_WIDTH(PA_WIDTH),\
						.VA_WIDTH(VA_WIDTH),\
						.L1D_SIZE(L1D_SIZE),\
						.L1D_NUM_WAYS(L1D_NUM_WAYS),\
						.STB_NUM(STB_NUM),\
						.REFILL_NUM(REFILL_NUM),\
						.SNPSLV_NUM(SNPSLV_NUM),\
						.VICTIM_NUM(VICTIM_NUM),\
						.INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),\
						.MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),\
						.MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX),\
						.SUPPORT_MMU(SUPPORT_MMU),\
						.ITLB_ENTRY_NUM(ITLB_ENTRY_NUM),\
						.DTLB_ENTRY_NUM(DTLB_ENTRY_NUM),\
						.PARAM_END(1)
`define REFILL_SLOT_PARAM parameter ID = 0,\
						  `CORE_PARAM

`define VICTIM_SLOT_PARAM parameter ID = 0,\
						  `CORE_PARAM

