module lsu #(
			 `CORE_PARAM
			)
(
	input  wire clk_i,
	input  wire rst_i,
	// interface with core pipeline
	input  wire opcode_valid_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] opcode_opcode_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] opcode_pc_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] opcode_ra_operand_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] opcode_rb_operand_i,
	output wire writeback_valid_o,
	output wire [`INSTRUCTION_WIDTH-1:0] writeback_value_o,
	output wire [ 5:0] writeback_exception_o,
	output wire stall_o,//indicate ls1 stall
	
	// interface with stb
	input  wire tlb_hit_ls1_i,
	input  wire tlb_load_fault_ls1_i,
	input  wire tlb_store_fault_ls1_i,
	input  wire [`PA_WIDTH-1:12] tlb_ppn_ls1_i,
	output wire [`VA_WIDTH-1:12] lsu_vpn_ls1_o,
	output wire lsu_tlb_lookup_ls1_o,
	output wire lsu_tlb_load_ls1_o,
	
	// intetface with l1d pipeline
	input  wire l1d_ack_dc1_i,
	input  wire l1d_hit_dc2_i,
	input  wire [(`L1D_NUM_WAYS*`L1D_TAG_STATE_WIDTH)-1:0] l1d_way_states_dc2_i,
	input  wire [(`L1D_NUM_WAYS*`L1D_TAG_DATA_WIDTH)-1:0] l1d_way_tags_dc2_i,
	input  wire [(`L1D_BANK_SIZE*8)-1:0] l1d_data_dc2_i,
	output wire lsu_l1d_req_dc1_o,
	output wire [`PA_WIDTH-1:0] lsu_l1d_addr_dc1_o,
	
	// interface with cachealbe/nc store
	input  wire stb_lsu_store_ok_ls3_i,
	input  wire stb_lsu_store_excl_ok_ls3_i,//todo
	input  wire nc_store_lsu_store_ok_ls3_i,
	input  wire nc_store_lsu_store_excl_ok_ls3_i,
	output wire lsu_store_ls3_o,
	output wire lsu_store_cacheable_ls3_o,//todo
	output wire lsu_store_excl_ls3_o,//todo
	output wire [`INSTRUCTION_WIDTH-1:0] lsu_store_data_ls3_o,
	output wire [(`INSTRUCTION_WIDTH/8)-1:0] lsu_store_be_ls3_o,
	output wire [1:0] lsu_store_size_ls3_o,//2'h0:byte;2'h1:half word;2'h2:word;2'h3:double word;//todo
	output wire [`PA_WIDTH-1:0] lsu_store_addr_ls3_o,
	
	// interface with victim
	input  wire victim_hit_ls2_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] victim_hit_data_ls2_i,
	output wire [`PA_WIDTH-1:0] lsu_victim_addr_ls2_o,
	output wire lsu_victim_ah_check_ls2_o,
	
	// interface with refill
	input  wire refill_ok_i,
	input  wire refill_req_ack_ls3_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] refill_data_i,
	output wire lsu_refill_req_ls3_o,
	output wire [(`L1D_NUM_WAYS*`L1D_TAG_STATE_WIDTH)-1:0] lsu_refill_way_states_ls3_o,
	output wire [(`L1D_NUM_WAYS*`L1D_TAG_DATA_WIDTH)-1:0 ] lsu_refill_way_tags_ls3_o,
	output wire [`PA_WIDTH-1:0] lsu_refill_addr_ls3_o,
	
	// interface with nc load
	input  wire nc_load_ok_ls3_i,
	input  wire [`INSTRUCTION_WIDTH-1:0] nc_load_data_ls3_i,
	output wire lsu_nc_load_req_ls3_o,
	output wire lsu_nc_load_size_ls3_o,
	output wire [`INSTRUCTION_WIDTH-1:0] lsu_nc_load_addr_ls3_o,
	
	// interface with l1 bus
	// for lp moniter check
	input  wire ac_valid_i,//todo
	input  wire [`AC_OPCODE_WIDTH-1:0] ac_opcode_i,//todo
	input  wire [`PA_WIDTH-1:0] ac_addr_i//todo
);
integer i;
genvar gi;
wire fault_ls3_w;
wire stall_ls3_w;
wire nc_load_w;
wire nc_load_stall_w;
wire c_load_stall_w;
wire [`INSTRUCTION_WIDTH-1:0] c_load_data_ls3_w;
reg refill_req_flag_q;
wire refill_req_flag_enable_w;
wire [`INSTRUCTION_WIDTH-1:0] load_data_ls3_w;
wire nc_store_req_w;
wire nc_store_w;
wire nc_store_stall_w;
wire excl_miss_lp_w;
wire c_store_req_w;// ToDo : stb_lsu_ack_ls3_i
wire c_store_w;
wire c_store_stall_w;
wire [`INSTRUCTION_WIDTH-1:0] lb_data_w;
reg [7:0] lb_data_r;
wire [`INSTRUCTION_WIDTH-1:0] lh_data_w;
reg [15:0] lh_data_r;
wire [`INSTRUCTION_WIDTH-1:0] lw_data_w;
wire [`INSTRUCTION_WIDTH-1:0] sc_data_w; 
wire [`INSTRUCTION_WIDTH-1:0] writeback_value_w;
reg l1d_hit_ls3_q;
reg [(`L1D_NUM_WAYS*`L1D_TAG_STATE_WIDTH)-1:0] l1d_way_states_ls3_q;
reg [(`L1D_NUM_WAYS*`L1D_TAG_DATA_WIDTH)-1:0] l1d_way_tags_ls3_q;
reg [(`L1D_BANK_SIZE*8)-1:0] l1d_data_ls3_q;
reg lp_detected_ls3_q;
reg victim_detected_ls3_q;
reg [`INSTRUCTION_WIDTH-1:0] victim_data_ls3_q;
wire data_ls3_enable_w;
reg valid_ls3_q;
wire valid_ls3_enable_w;
wire valid_ls3_nxt_w;
wire load_unaligned_w;
wire store_unaligned_w;
wire load_fault_w;
wire store_fault_w;
reg valid_ls2_q;
wire valid_ls2_enable_w;
wire valid_ls2_nxt_w;
wire stall_ls2_w;
wire fault_ls2_w;
reg got_l1d_info_q;
wire got_l1d_info_enable_w;
wire register_l1d_info_enable_w;
reg l1d_hit_ls2_q;
reg [(`L1D_NUM_WAYS*`L1D_TAG_STATE_WIDTH)-1:0] l1d_way_states_ls2_q;
reg [(`L1D_NUM_WAYS*`L1D_TAG_DATA_WIDTH)-1:0] l1d_way_tags_ls2_q;
reg [(`L1D_BANK_SIZE*8)-1:0] l1d_data_ls2_q;
wire l1d_hit_ls2_w;
wire [(`L1D_NUM_WAYS*`L1D_TAG_STATE_WIDTH)-1:0] l1d_way_states_ls2_w;
wire [(`L1D_NUM_WAYS*`L1D_TAG_DATA_WIDTH)-1:0] l1d_way_tags_ls2_w;
wire [(`L1D_BANK_SIZE*8)-1:0] l1d_data_ls2_w;
wire lp_write_w;
wire lp_check_w;
wire excl_w;
wire lp_detected_w;
reg [`INSTRUCTION_WIDTH-1:0] va_ls3_q      ;   
reg [`INSTRUCTION_WIDTH-1:0] pa_ls3_q      ;   
reg [`INSTRUCTION_WIDTH-1:0] data_ls3_q   ;
reg [`INSTRUCTION_WIDTH-1:0] pc_ls3_q ;  
reg [(`INSTRUCTION_WIDTH/8)-1:0] wr_ls3_q             ;
reg cacheable_ls3_q      ;
reg [2:0] fault_ls3_q      ;
reg load_ls3_q           ; 
reg xb_ls3_q             ; 
reg xh_ls3_q             ; 
reg ls_ls3_q             ; 
reg excl_ls3_q;
reg valid_ls1_q;
wire valid_ls1_enable_w;
wire valid_ls1_nxt_w;
wire detected_store_load_hazard_w;
reg got_tlb_info_q;
wire got_tlb_info_enable_w;
wire register_tlb_info_enable_w;
reg [`PA_WIDTH-1:12] ppn_q;
reg [1:0] tlb_fault_q;
wire [`PA_WIDTH-1:12] ppn_ls1_w;
wire [1:0] tlb_fault_ls1_w;
wire stall_ls1_w;
wire stall_ls1_self_w;
reg [`INSTRUCTION_WIDTH-1:0] va_ls2_q      ;   
reg [`INSTRUCTION_WIDTH-1:0] pa_ls2_q      ;   
reg [`INSTRUCTION_WIDTH-1:0] data_ls2_q   ;
reg [`INSTRUCTION_WIDTH-1:0] pc_ls2_q ;  
reg [(`INSTRUCTION_WIDTH/8)-1:0] wr_ls2_q             ; 
reg cacheable_ls2_q      ;
reg [2:0] fault_ls2_q      ;
reg load_ls2_q           ; 
reg xb_ls2_q             ; 
reg xh_ls2_q             ; 
reg ls_ls2_q             ; 
reg excl_ls2_q;
wire data_ls2_enable_w;
wire [`INSTRUCTION_WIDTH-1:0] va_w;
wire [`INSTRUCTION_WIDTH-1:0] load_va_w;
wire [`INSTRUCTION_WIDTH-1:0] store_va_w;
wire va_unaligned_w;
wire [`INSTRUCTION_WIDTH-1:0] store_data_w;
wire [(`INSTRUCTION_WIDTH/8)-1:0] store_we_w;
wire [`INSTRUCTION_WIDTH-1:0] sw_data_w;
wire [(`INSTRUCTION_WIDTH/8)-1:0] sw_we_w;
wire [`INSTRUCTION_WIDTH-1:0] sh_data_w;
wire [(`INSTRUCTION_WIDTH/8)-1:0] sh_we_w;
wire [`INSTRUCTION_WIDTH-1:0] sb_data_w;
wire [(`INSTRUCTION_WIDTH/8)-1:0] sb_we_w;
reg [`INSTRUCTION_WIDTH-1:0] va_ls1_q      ;   
reg [`INSTRUCTION_WIDTH-1:0] data_ls1_q   ;
reg [`INSTRUCTION_WIDTH-1:0] pc_ls1_q ;  
reg [(`INSTRUCTION_WIDTH/8)-1:0] wr_ls1_q             ; 
reg cacheable_ls1_q      ;
reg unaligned_ls1_q      ;
reg load_ls1_q           ; 
reg xb_ls1_q             ; 
reg xh_ls1_q             ; 
reg ls_ls1_q             ; 
reg excl_ls1_q;
wire ls1_data_enable_w;
wire lb_w;
wire lub_w;
wire lh_w;
wire luh_w;
wire lw_w;
wire luw_w;
wire lrw_w;
wire sb_w;
wire sh_w;
wire sw_w;
wire scw_w;
wire load_inst_w;
wire load_signed_inst_w;
wire store_inst_w;
wire sw_lw_w;
wire sh_lh_w;
// ******************* AGU state ****************************
// Decode
// AGU
// Check misaligned
// Cacheable:
// ***********************************************************

//---------------------------Decode
//wire csrrw_w;
assign lb_w  = (opcode_opcode_i & `INST_LB_MASK) == `INST_LB;
assign lub_w = (opcode_opcode_i & `INST_LBU_MASK) == `INST_LBU;
assign lh_w  = (opcode_opcode_i & `INST_LH_MASK) == `INST_LH;
assign luh_w = (opcode_opcode_i & `INST_LHU_MASK) == `INST_LHU;
assign lw_w  = (opcode_opcode_i & `INST_LW_MASK) == `INST_LW;
assign luw_w = (opcode_opcode_i & `INST_LWU_MASK) == `INST_LWU;
assign lrw_w = (opcode_opcode_i & `INST_LRW_MASK) == `INST_LRW;
assign sb_w  = (opcode_opcode_i & `INST_LB_MASK) == `INST_SB;
assign sh_w  = (opcode_opcode_i & `INST_LH_MASK) == `INST_SH;
assign sw_w  = (opcode_opcode_i & `INST_LW_MASK) == `INST_SW;
assign scw_w = (opcode_opcode_i & `INST_SCW_MASK) == `INST_SCW;
//assign csrrw_w = opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW; 

assign load_signed_inst_w = lb_w | lh_w | lw_w;
assign load_inst_w        = lub_w | luh_w | luw_w | load_signed_inst_w;
assign store_inst_w       = sb_w | sh_w | sw_w | scw_w;
assign sw_lw_w            = sw_w | lw_w | luw_w | lrw_w | scw_w;
assign sh_lh_w            = sh_w | luh_w | lh_w;

//-----------------------------AGU
assign load_va_w  = opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]};
assign store_va_w = opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:25], opcode_opcode_i[11:7]}; 
assign va_w = ({`INSTRUCTION_WIDTH{/*csrrw_w |*/ lrw_w | scw_w}} & opcode_ra_operand_i) |
			  ({`INSTRUCTION_WIDTH{load_inst_w}} & load_va_w) |
			  ({`INSTRUCTION_WIDTH{~(/*csrrw_w|*/ lrw_w | scw_w  | load_inst_w)}} & store_va_w);

// ---------------check misaligned

assign va_unaligned_w = (sw_lw_w & (|va_w[1:0])) |
						(sh_lh_w & va_w[0]);
// ----------------------store data & wr

//sw
generate
	if (`INSTRUCTION_WIDTH == 32) begin
		assign sw_data_w = opcode_rb_operand_i;
		assign sw_we_w   = 4'hf;
	end else begin
		for (gi=0;gi<(`INSTRUCTION_WIDTH/32);gi=gi+1) begin
			assign sw_data_w[(gi*32) +: 32] = opcode_rb_operand_i;
			assign sw_we_w[(gi*4) +: 4] =  (va_w[$clog2(`INSTRUCTION_WIDTH/32)+1 : 2] == gi) ? 4'hf : 4'h0;
		end
	end
endgenerate

// sh
generate
	for (gi=0;gi<(`INSTRUCTION_WIDTH/16);gi=gi+1) begin
		assign sh_data_w[(gi*16) +: 16] = opcode_rb_operand_i[15:0];
		assign sh_we_w[(gi*2) +: 2]  = (va_w[$clog2(`INSTRUCTION_WIDTH/16):1] == gi) ? 2'b11: 2'b0;
	end
endgenerate

// sb
generate
	for (gi=0;gi<(`INSTRUCTION_WIDTH/8);gi=gi+1) begin
		assign sh_data_w[(gi*8) +: 8] = opcode_rb_operand_i[7:0];
		assign sh_we_w[gi] = va_w[$clog2(`INSTRUCTION_WIDTH/8):0] == gi;
	end
endgenerate

assign store_data_w = ({`INSTRUCTION_WIDTH{sw_w}} & sw_data_w) |
					  ({`INSTRUCTION_WIDTH{sh_w}} & sh_data_w) |
					  ({`INSTRUCTION_WIDTH{sb_w}} & sb_data_w);
assign store_we_w   = ({(`INSTRUCTION_WIDTH/8){sw_w}} & sw_we_w) |
					  ({(`INSTRUCTION_WIDTH/8){sh_w}} & sh_we_w) |
					  ({(`INSTRUCTION_WIDTH/8){sb_w}} & sb_we_w);
//*********************************************************************************************

// AGU --> LS1

// ls1 data
assign ls1_data_enable_w = opcode_valid_i & (~stall_ls1_w);
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		va_ls1_q <= 'b0;
		data_ls1_q <= 'b0;
		pc_ls1_q <= 'b0;
		load_ls1_q <= 'b0;//1'b1 mean load,1'b0 mean store
		wr_ls1_q <= 'b0;
		cacheable_ls1_q <= 'b0;
		unaligned_ls1_q <= 'b0;
		xb_ls1_q <= 'b0;
		xh_ls1_q <= 'b0;
		ls_ls1_q <= 'b0;
		excl_ls1_q <= 'b0;
	end else begin
		if (ls1_data_enable_w) begin
			va_ls1_q 		<= va_w;
			data_ls1_q 		<= store_data_w;
			pc_ls1_q   		<= opcode_pc_i;
			load_ls1_q 		<= load_inst_w | lrw_w;
			wr_ls1_q   		<= store_we_w;
			cacheable_ls1_q <= ((va_w >= MEM_CACHE_ADDR_MIN) & (va_w <= MEM_CACHE_ADDR_MAX));
			unaligned_ls1_q <= va_unaligned_w;
			xb_ls1_q        <= lb_w | lub_w | sb_w;
			xh_ls1_q        <= lh_w | luh_w | sh_w;
			ls_ls1_q        <= load_signed_inst_w;
			excl_ls1_q      <= lrw_w | scw_w;
		end
	end
// ls1 valid 

assign valid_ls1_enable_w = (|writeback_exception_o) |
						    (~stall_ls1_w);
assign valid_ls1_nxt_w    = opcode_valid_i & (load_inst_w | lrw_w  | store_inst_w) & ~(|writeback_exception_o);
always @(posedge clk_i or rst_i)
	if (rst_i) begin
		valid_ls1_q <= 0;
	end else begin
		if (valid_ls1_enable_w)
			valid_ls1_q <= valid_ls1_nxt_w;
	end
//***************************************************************************************

// *************************LS1 stage
// For load check store-load hazard with ls2 & ls3,If detected hazard,dont send l1d
// req and stall.
// If ls2/ls3 has exception,dont lookup tlb.
// Lookup tlb.If tlb miss,then stall until tlb hit
// For uncacheable addr,after got ppn enter ls2 stage
// For cacheable addr
// 	i.For load.After got ppn,then send a req to l1d pipeline.If the req dont
// 	got l1d arbitration,then stall until l1d ack
// 	ii.For store,After got ppn,enter ls2 stage
// ****************************************************************

// check store-load hazard
assign detected_store_load_hazard_w =	load_ls1_q &
										((valid_ls2_q & (~load_ls2_q) & (va_ls1_q[`PA_WIDTH-1:$clog2(`L1D_CACHELINE_SIZE)] == va_ls2_q[`PA_WIDTH-1:$clog2(`L1D_CACHELINE_SIZE)])) |
										 (valid_ls3_q & (~load_ls3_q) & (va_ls1_q[`PA_WIDTH-1:$clog2(`L1D_CACHELINE_SIZE)] == va_ls3_q[`PA_WIDTH-1:$clog2(`L1D_CACHELINE_SIZE)])));
// -----------------------------------------------------------------------------
// lookup tlb
assign lsu_vpn_ls1_o = va_ls1_q[`VA_WIDTH:12];
assign lsu_tlb_lookup_ls1_o = valid_ls1_q & (~got_tlb_info_q) & (~unaligned_ls1_q)  & (~fault_ls2_w) & (~fault_ls3_w);
assign lsu_tlb_load_ls1_o = load_ls1_q;
// -------------------------------------------------------------------------------


// when tlb hit and ls1 stall,then need to register tlb info
assign register_tlb_info_enable_w = tlb_hit_ls1_i &(~got_tlb_info_q) & stall_ls1_w;
assign got_tlb_info_enable_w =	(register_tlb_info_enable_w) |
								(got_tlb_info_q & (~stall_ls1_w));
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		got_tlb_info_q <= 0;
	end else begin
		if (got_tlb_info_enable_w)
			got_tlb_info_q <= ~got_tlb_info_q;
	end
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		ppn_q <= 'b0;
		tlb_fault_q <= 'b0;
	end else begin
		if (register_tlb_info_enable_w)
			ppn_q <= tlb_ppn_ls1_i;
			tlb_fault_q <= {tlb_store_fault_ls1_i,tlb_load_fault_ls1_i};
	end

assign ppn_ls1_w = got_tlb_info_q ? ppn_q : tlb_ppn_ls1_i;
assign tlb_fault_ls1_w = got_tlb_info_q ? tlb_fault_q : {tlb_store_fault_ls1_i,tlb_load_fault_ls1_i};
// -----------------------------------------------------------

wire [`PA_WIDTH-1:0] pa_ls1_w;
assign pa_ls1_w = {`PA_WIDTH{1'b1}} & {ppn_ls1_w,va_ls1_q[11:0]};
// send l1d pipeline req
assign lsu_l1d_req_dc1_o =	valid_ls1_q & 
							/*cacheable_ls1_q & */
							load_ls1_q & 
							(tlb_hit_ls1_i | got_tlb_info_q) & // got tlb info
							(~detected_store_load_hazard_w) & //to long.ToDo:it must be delete
							~(fault_ls2_w | stall_ls2_w) & // there are no stall or fault in ls2
							(~fault_ls3_w);//there is no stall in ls3
assign lsu_l1d_addr_dc1_o = pa_ls1_w;


assign stall_ls1_self_w = (~unaligned_ls1_q) &//if detected unaligned in ls1 then stop everything action
						  ((~(tlb_hit_ls1_i | got_tlb_info_q)) | //didnt got tlb info
						   detected_store_load_hazard_w |//detected store_load hazard
						   (~l1d_ack_dc1_i & load_ls1_q /*& cacheable_ls1_q*/));// cacheable load didnt got l1d pipeline arbitration

assign stall_ls1_w =	valid_ls1_q &
						(stall_ls1_self_w | stall_ls2_w);
// --------------------------------------------------------------------------------
// --------------LS1 to LS2---------------------------------------------------
// ls2 data
assign data_ls2_enable_w = valid_ls1_q & (~stall_ls2_w);
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		va_ls2_q <= 'b0;
		pa_ls2_q <= 'b0;
		data_ls2_q <= 'b0;
		pc_ls2_q <= 'b0;
		wr_ls2_q <= 'b0;
		cacheable_ls2_q <= 'b0;
		fault_ls2_q <= 'b0;
		load_ls2_q <= 'b0;
		xb_ls2_q <= 'b0;
		xh_ls2_q <= 'b0;
		ls_ls2_q <= 'b0;
		excl_ls2_q <= 'b0;
	end else begin
		if (data_ls2_enable_w) begin
			va_ls2_q <= va_ls1_q;
			pa_ls2_q <= pa_ls1_w;
			data_ls2_q <= data_ls1_q;
			pc_ls2_q <= pc_ls1_q;
			wr_ls2_q <= wr_ls1_q;
			cacheable_ls2_q <= ((pa_ls1_w >= MEM_CACHE_ADDR_MIN) & (pa_ls1_w <= MEM_CACHE_ADDR_MAX));
			fault_ls2_q <= {tlb_fault_ls1_w,unaligned_ls1_q};
			load_ls2_q <= load_ls1_q;
			xb_ls2_q <= xb_ls1_q;
			xh_ls2_q <= xh_ls1_q;
			ls_ls2_q <= ls_ls1_q;
			excl_ls2_q <= excl_ls1_q;
		end
	end
assign valid_ls2_enable_w = (~stall_ls2_w) |
							(|writeback_exception_o);
assign valid_ls2_nxt_w = valid_ls1_q & (~stall_ls1_self_w) & ~(|writeback_exception_o);
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		valid_ls2_q <= 'b0;
	end else begin
		if (valid_ls2_enable_w)
			valid_ls2_q <= valid_ls2_nxt_w;
	end
// ---------------------------------------------------------------------------
// ************************** LS2 stage ***********************************
// For uncacheable addr,enter ls3 stage if there is not stall in ls3
// For cacheable address
// 	If ls3 stall,then register l1d pipeline result
// 	If ls3 didnt stall,then lookup victim and register hit data.And
// 		i.for excl load,register LP
// 		ii.for excl store,lookup LP moniter,register moniter result.
// ************************************************************************
assign stall_ls2_w = valid_ls2_q & stall_ls3_w;

assign fault_ls2_w = valid_ls2_q & (|fault_ls2_q);


// if ls2 stall,register l1d pipeline info
assign register_l1d_info_enable_w = (~got_l1d_info_q & stall_ls2_w);
assign got_l1d_info_enable_w = register_l1d_info_enable_w | (got_l1d_info_q & (~stall_ls2_w));
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		got_l1d_info_q <= 'b0;
	end else begin
		if (got_l1d_info_enable_w)
			got_l1d_info_q <= ~got_l1d_info_q;
	end
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		l1d_hit_ls2_q <= 'b0;
		l1d_way_states_ls2_q <= 'b0;
		l1d_way_tags_ls2_q <= 'b0;
		l1d_data_ls2_q <= 'b0;
	end else begin
		if (register_l1d_info_enable_w) begin
			l1d_hit_ls2_q <= l1d_hit_dc2_i;
			l1d_way_states_ls2_q <= l1d_way_states_dc2_i;
			l1d_way_tags_ls2_q <= l1d_way_tags_dc2_i;
			l1d_data_ls2_q <= l1d_data_dc2_i;
		end
	end
assign l1d_hit_ls2_w		 = got_l1d_info_q ? l1d_hit_ls2_q : l1d_hit_dc2_i;
assign l1d_way_states_ls2_w = got_l1d_info_q ? l1d_way_states_ls2_q : l1d_way_states_dc2_i;
assign l1d_way_tags_ls2_w 	= got_l1d_info_q ? l1d_way_tags_ls2_q : l1d_way_tags_dc2_i;
assign l1d_data_ls2_w	 	= got_l1d_info_q ? l1d_data_ls2_q : l1d_data_dc2_i;
//---------------------------------------------------------------------------

// check addr hazard with victim slot
assign lsu_victim_addr_ls2_o = va_ls2_q;
assign lsu_victim_ah_check_ls2_o = valid_ls2_q & (~stall_ls3_w) & cacheable_ls2_q & load_ls2_q; 


// excl -----------------------------------------------
// only for cacheable addr
assign excl_w = valid_ls2_q & excl_ls2_q;
assign lp_write_w = excl_w & cacheable_ls2_q & load_ls2_q & (~stall_ls3_w);
assign lp_check_w = excl_w & cacheable_ls2_q & (~load_ls2_q) & (~stall_ls3_w);
lp_monitor	#(
			 `CORE_PARAM_INST
			)
u_lp_moniter(
	.clk_i(clk_i),
	.rst_i(rst_i),

	// interface with lsu      
	.write_i(lp_write_w),
	.check_i(lp_check_w),
	.addr_i(pa_ls2_q),
	.detected_o(lp_detected_w),

	// interface with l1 bus
	// AC
	.ac_valid_i(ac_valid_i),
	.ac_opcode_i(ac_opcode_i),
	.ac_addr_i(ac_addr_i)
);

// ************************************************************************

// **********************LS2 to LS3***************************************

assign data_ls3_enable_w = valid_ls2_q & (~stall_ls3_w);
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		va_ls3_q <= 'b0;
		pa_ls3_q <= 'b0;
		data_ls3_q <= 'b0;
		pc_ls3_q <= 'b0;
		wr_ls3_q <= 'b0;
		cacheable_ls3_q <= 'b0;
		fault_ls3_q <= 'b0;
		load_ls3_q <= 'b0;
		xb_ls3_q <= 'b0;
		xh_ls3_q <= 'b0;
		ls_ls3_q <= 'b0;
		excl_ls3_q <= 'b0;
		l1d_hit_ls3_q <= 'b0;
		l1d_way_states_ls3_q <= 'b0;
		l1d_way_tags_ls3_q <= 'b0;
		l1d_data_ls3_q <= 'b0;
		lp_detected_ls3_q <= 'b0;
		victim_detected_ls3_q <= 'b0;
		victim_data_ls3_q <= 'b0;
	end else begin
		if (data_ls3_enable_w) begin
			va_ls3_q <= va_ls2_q;
			pa_ls3_q <= pa_ls2_q;
			data_ls3_q <= data_ls2_q;
			pc_ls3_q <= pc_ls2_q;
			wr_ls3_q <= wr_ls2_q;
			cacheable_ls3_q <= cacheable_ls2_q;
			fault_ls3_q <= fault_ls2_q;
			load_ls3_q <= load_ls2_q;
			xb_ls3_q <= xb_ls2_q;
			xh_ls3_q <= xh_ls2_q;
			ls_ls3_q <= ls_ls2_q;
			excl_ls3_q <= excl_ls2_q;
			l1d_hit_ls3_q <= l1d_hit_ls2_w;
			l1d_way_states_ls3_q <= l1d_way_states_ls2_w;
			l1d_way_tags_ls3_q <= l1d_way_tags_ls2_w;
			l1d_data_ls3_q <= l1d_data_ls2_w;
			lp_detected_ls3_q <= lp_detected_w;
			victim_detected_ls3_q <= victim_hit_ls2_i;
			victim_data_ls3_q <= victim_hit_data_ls2_i;
		end
	end

assign valid_ls3_enable_w = (~stall_ls3_w) |
							(|writeback_exception_o);
assign valid_ls3_nxt_w = valid_ls2_q & ~(|writeback_exception_o);
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		valid_ls3_q <= 'b0;
	end else begin
		if (valid_ls3_enable_w)
			valid_ls3_q <= valid_ls3_nxt_w;
	end
// ***********************************************************************


// **********************************LS3 stage******************************
// Resolve exception,if detect exception,cancel all action
// For uncacheable address
// 	send a req to nc load/store and stall until load/store finsih
// For cacheable address
// 	For load
// 		i.If l1d/victim hit,then finished and return data to core pipeline.
// 		ii.If l1d&victim miss,then send a req to refill slot,and stall until
// 		refill finish.
// 	For store!!!!!!!!!!!!!!!!!!!!!!!!!
// 		If excl store check lp_detected_ls3_q is 1'b0,
// 		send a store and stall until stb finish(ToDo:non-block stb)
// ***************************************************************************

//-----------------------exception---------------------------------
assign load_unaligned_w 	= valid_ls3_q & load_ls3_q & fault_ls3_q[0];
assign store_unaligned_w	= valid_ls3_q & (~load_ls3_q) & fault_ls3_q[0];
assign load_fault_w 		= valid_ls3_q & fault_ls3_q[1];
assign store_fault_w 		= valid_ls3_q & fault_ls3_q[2];
assign fault_ls3_w = |writeback_exception_o;

// ls3 stall
assign stall_ls3_w =	valid_ls3_q &
						(~fault_ls3_w) &
						(c_load_stall_w | nc_load_stall_w | c_store_stall_w | nc_store_stall_w);
//---------------------------LOAD----------------------------------------
// uncacheable addr
assign lsu_nc_load_req_ls3_o = valid_ls3_q & load_ls3_q & (~cacheable_ls3_q) & (~fault_ls3_w);
assign lsu_nc_load_size_ls3_o = ({2{xb_ls3_q}} & 2'b00) |
								({2{xh_ls3_q}} & 2'b01) |
								({2{~(xb_ls3_q | xh_ls3_q)}} & 2'b10);
assign lsu_nc_load_addr_ls3_o = {`PA_WIDTH{1'b1}} & pa_ls3_q;
assign nc_load_stall_w = load_ls3_q & (~cacheable_ls3_q) & (~nc_load_ok_ls3_i);
// cacheable addr
assign c_load_stall_w = ~(l1d_hit_ls3_q | victim_detected_ls3_q) & (~refill_ok_i) & cacheable_ls3_q & load_ls3_q;
assign c_load_data_ls3_w =	({`INSTRUCTION_WIDTH{l1d_hit_ls3_q}} & l1d_data_ls3_q) |
							({`INSTRUCTION_WIDTH{victim_detected_ls3_q}} & victim_data_ls3_q) |
							({`INSTRUCTION_WIDTH{refill_ok_i}} & refill_data_i);

// send a refill req
assign refill_req_flag_enable_w = (refill_req_flag_q & refill_req_ack_ls3_i) | (valid_ls3_q & (~stall_ls3_w) & (~refill_req_flag_q));
always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		refill_req_flag_q <= 1'b1;
	end else begin
		if (refill_req_flag_enable_w)
			refill_req_flag_q <= ~refill_req_flag_q;
	end

assign lsu_refill_req_ls3_o = valid_ls3_q & load_ls3_q & cacheable_ls3_q & (~fault_ls3_w) & ~(l1d_hit_ls3_q | victim_detected_ls3_q) & refill_req_flag_q;
assign lsu_refill_way_states_ls3_o = l1d_way_states_ls3_q;
assign lsu_refill_way_tags_ls3_o = l1d_way_tags_ls3_q;
assign lsu_refill_addr_ls3_o = {`PA_WIDTH{1'b1}} & pa_ls3_q;

// load data
assign load_data_ls3_w =	({`INSTRUCTION_WIDTH{~cacheable_ls3_q}} & nc_load_data_ls3_i) |
							({`INSTRUCTION_WIDTH{cacheable_ls3_q}} & c_load_data_ls3_w);

// -------------------------------------------------------------------------------------------------------

// ----------------------------------STORE-------------------------------------
// uncacheable addr
assign nc_store_w =  (~load_ls3_q) & (~cacheable_ls3_q);
assign nc_store_req_w = valid_ls3_q & nc_store_w & (~fault_ls3_w);

assign nc_store_stall_w = nc_store_w & (~nc_store_lsu_store_ok_ls3_i);
// cacheable addr
// resolved excl store
assign excl_miss_lp_w = excl_ls3_q & (~lp_detected_ls3_q); 

assign c_store_w = (~load_ls3_q) & (cacheable_ls3_q);
assign c_store_req_w = valid_ls3_q & c_store_w & (~excl_miss_lp_w) & (~fault_ls3_w);

assign c_store_stall_w = c_store_w & (~excl_miss_lp_w) & (~stb_lsu_store_ok_ls3_i);

// send req to stb/nc
assign lsu_store_ls3_o = nc_store_req_w | c_store_req_w;
assign lsu_store_cacheable_ls3_o = cacheable_ls3_q;
assign lsu_store_excl_ls3_o = excl_ls3_q;
assign lsu_store_data_ls3_o = data_ls3_q;
assign lsu_store_be_ls3_o = wr_ls3_q;
assign lsu_store_size_ls3_o =	({2{xb_ls3_q}} & 2'b00) |
							({2{xh_ls3_q}} & 2'b01) |
							({2{~(xb_ls3_q | xh_ls3_q)}} & 2'b10);
assign lsu_store_addr_ls3_o = pa_ls3_q;

// -------------------------------------------------------------------------------------

// ---------------------return data to arch --------------------------------
// lb,lub
assign lb_data_w[`INSTRUCTION_WIDTH-1:8] = {(`INSTRUCTION_WIDTH-8){ls_ls3_q & lb_data_w[7]}};
assign lb_data_w[7:0] = lb_data_r;
always @(*) begin
	lb_data_r = 0;
	for (i=0;i<(`INSTRUCTION_WIDTH/8);i += 1) begin
		lb_data_r = lb_data_r | ({8{pa_ls3_q[$clog2(`INSTRUCTION_WIDTH/8)-1:0] == i}} & load_data_ls3_w[(i*8) +: 8]);
	end
end

// lh,luh
assign lh_data_w[`INSTRUCTION_WIDTH-1:16] = {(`INSTRUCTION_WIDTH-16){ls_ls3_q & lh_data_w[15]}};
assign lh_data_w[15:0] = lh_data_r;
always @(*) begin
	lh_data_r = 0;
	for (i=0;i<(`INSTRUCTION_WIDTH/16);i += 1) begin
		lh_data_r = lh_data_r | ({16{pa_ls3_q[$clog2(`INSTRUCTION_WIDTH/8)-1:1] == i}} & load_data_ls3_w[(i*16) +: 16]);
	end
end

// lw,luw
generate
if(`INSTRUCTION_WIDTH == 32) begin
	assign lw_data_w = load_data_ls3_w;
end else begin
	reg [31:0] lw_data_r;
	assign lw_data_w[`INSTRUCTION_WIDTH-1:32] = {(`INSTRUCTION_WIDTH-32){ls_ls3_q & lw_data_w[31]}};
	assign lw_data_w[31:0] = lw_data_r;
	always @(*) begin
		lw_data_r = 0;
		for (i=0;i<(`INSTRUCTION_WIDTH/32);i += 1) begin
			lw_data_r = lw_data_r | ({32{pa_ls3_q[$clog2(`INSTRUCTION_WIDTH/8)-1:2] == i }} & load_data_ls3_w[(i*32) +: 32]);
		end
	end
end
endgenerate


// excl store
assign sc_data_w = {{(`INSTRUCTION_WIDTH-1){1'b0}},stb_lsu_store_excl_ok_ls3_i};

assign writeback_value_w =	fault_ls3_w ?	va_ls3_q :
											load_ls3_q ?	(({`INSTRUCTION_WIDTH{xb_ls3_q}} & lb_data_w) |
															 ({`INSTRUCTION_WIDTH{xh_ls3_q}} & lh_data_w) |
															 ({`INSTRUCTION_WIDTH{~(xb_ls3_q | xh_ls3_q)}} & lw_data_w)) :
															sc_data_w;

assign writeback_valid_o = valid_ls3_q & (~stall_ls3_w);
assign writeback_value_o = writeback_value_w;
assign writeback_exception_o =	({6{load_unaligned_w}} & 6'b000100) |
								({6{store_unaligned_w}} & 6'b001000) |
								({6{load_fault_w}} & 6'b000001) |
								({6{store_fault_w}} & 6'b000010);
assign stall_o = stall_ls1_w;
endmodule
