// Defines
// some basic sizes of things
`define DATA	[15:0]
`define ADDR	[15:0] //address
`define INST	[15:0] //instruction
`define SIZE	[65535:0]
`define STATE	[7:0]  //state number size & opcode size
`define REGS	[15:0] //size of registers
`define REGNAME	[3:0]  //16 registers to choose from
`define WORD	[15:0] //16-bit words
`define HALF	[7:0]	//8-bit half-words
`define NIB		[3:0]	//4-bit nibble
`define HI8		[15:8]
`define LO8		[7:0]
`define HIGH8	[15:8]
`define LOW8	[7:0]
`define MEMSIZE [65535:0]

`define	INT	signed [15:0]	// integer size
`define FLOAT	[15:0]	// half-precision float size
`define FSIGN	[15]	// sign bit
`define FEXP	[14:7]	// exponent
`define FFRAC	[6:0]	// fractional part (leading 1 implied)

// Constants
`define	FZERO	16'b0	  // float 0
`define F32767  16'h46ff  // closest approx to 32767, actually 32640
`define F32768  16'hc700  // -32768


// the instruction fields
`define F_H		[15:12] //4-bit header (needed for short opcodes)
`define F_OP	[15:8]
`define F_D		[3:0]
`define F_S		[7:4]
`define F_C8	[11:4]
`define F_ADDR	[11:4]

// Used in posit840.vmem
`define SIZE840 [39:0]
`define RECI [7:0]
`define FLTPOS [23:8]
`define INTPOS [31:24]
`define POSINT [39:32]

// Used in posit1624.vmem
`define SIZE1624 [23:0]
`define POSADD [7:0]
`define POSMUL [15:8]
`define POSFLT [23:16]

// lengths
`define WORD_LENGTH 16;

//long instruction headers
`define HCI8	4'hb
`define HCII	4'hc
`define HCUP	4'hd
`define HBNZ	4'hf
`define HBZ		4'he

// opcode values, also state numbers
//negf,pp2f,f2pp,dup : added but not implimented in verilog b/c new instructions
//addf replces addp, mulf replaces mulp, f2i replaces p2i, i2f replaces i2p, invf replaces invpa
// opcode values, also state numbers

`define OPADDI	8'h70
`define OPADDII	8'h71
`define OPMULI	8'h72
`define OPMULII	8'h73
`define OPSHI	8'h74
`define OPSHII	8'h75
`define OPSLTI	8'h76
`define OPSLTII	8'h77
`define OPDUP	8'h78

`define OPADDF	8'h60
`define OPADDPP	8'h61
`define OPMULF	8'h62
`define OPMULPP	8'h63

`define OPAND	8'h50
`define OPOR	8'h51
`define OPXOR	8'h52

`define OPLD	8'h40
`define OPST	8'h41

`define OPANYI	8'h30
`define OPANYII	8'h31
`define OPNEGI	8'h32
`define OPNEGII	8'h33
`define OPNEGF	8'h34

`define OPI2F	8'h20
`define OPII2PP	8'h21
`define OPF2I	8'h22
`define OPPP2II	8'h23
`define OPINVF	8'h24
`define OPINVPP	8'h25
`define OPF2PP	8'h26
`define OPPP2F 	8'h27

`define OPNOT	8'h10

`define OPJR	8'h01

`define OPTRAP	8'h00

`define OPCI8	8'hb0
`define OPCII	8'hc0
`define OPCUP	8'hd0

`define OPBZ	8'he0
`define OPBNZ	8'hf0

`define NOP 16'hffff

// state numbers (unused op codes)
`define IF	8'h96
`define ID	8'h97
`define EXMEM 8'h98
`define WB 8'h99

// Floating point modules from previous EE480
module lead0s(d, s);
output wire [4:0] d;
input wire `WORD s;
wire [4:0] t;
wire [7:0] s8;
wire [3:0] s4;
wire [1:0] s2;
assign t[4] = 0;
assign {t[3],s8} = ((|s[15:8]) ? {1'b0,s[15:8]} : {1'b1,s[7:0]});
assign {t[2],s4} = ((|s8[7:4]) ? {1'b0,s8[7:4]} : {1'b1,s8[3:0]});
assign {t[1],s2} = ((|s4[3:2]) ? {1'b0,s4[3:2]} : {1'b1,s4[1:0]});
assign t[0] = !s2[1];
assign d = (s ? t : 16);
endmodule

module fslt(torf, a, b);
output wire torf;
input wire `FLOAT a, b;
assign torf = (a `FSIGN && !(b `FSIGN)) ||
	      (a `FSIGN && b `FSIGN && (a[14:0] > b[14:0])) ||
	      (!(a `FSIGN) && !(b `FSIGN) && (a[14:0] < b[14:0]));
endmodule

module fadd(r, a, b);
output wire `FLOAT r;
input wire `FLOAT a, b;
wire `FLOAT s;
wire [8:0] sexp, sman, sfrac;
wire [7:0] texp, taman, tbman;
wire [4:0] slead;
wire ssign, aegt, amgt, eqsgn;
assign r = ((a == 0) ? b : ((b == 0) ? a : s));
assign aegt = (a `FEXP > b `FEXP);
assign texp = (aegt ? (a `FEXP) : (b `FEXP));
assign taman = (aegt ? {1'b1, (a `FFRAC)} : ({1'b1, (a `FFRAC)} >> (texp - a `FEXP)));
assign tbman = (aegt ? ({1'b1, (b `FFRAC)} >> (texp - b `FEXP)) : {1'b1, (b `FFRAC)});
assign eqsgn = (a `FSIGN == b `FSIGN);
assign amgt = (taman > tbman);
assign sman = (eqsgn ? (taman + tbman) : (amgt ? (taman - tbman) : (tbman - taman)));
lead0s m0(slead, {sman, 7'b0});
assign ssign = (amgt ? (a `FSIGN) : (b `FSIGN));
assign sfrac = sman << slead;
assign sexp = (texp + 1) - slead;
assign s = (sman ? (sexp ? {ssign, sexp[7:0], sfrac[7:1]} : 0) : 0);
endmodule

module fmul(r, a, b);
output wire `FLOAT r;
input wire `FLOAT a, b;
wire [15:0] m; // double the bits in a fraction, we need high bits
wire [7:0] e;
wire s;
assign s = (a `FSIGN ^ b `FSIGN);
assign m = ({1'b1, (a `FFRAC)} * {1'b1, (b `FFRAC)});
assign e = (((a `FEXP) + (b `FEXP)) -127 + m[15]);
assign r = (((a == 0) || (b == 0)) ? 0 : (m[15] ? {s, e, m[14:8]} : {s, e, m[13:7]}));
endmodule



// Floating-point reciprocal, 16-bit r=1.0/a
// Note: requires initialized inverse fraction lookup table
module frecip(r, a);
output wire `FLOAT r;
input wire `FLOAT a;
reg [6:0] look[127:0];
initial $readmemh("recip.vmem",look);
assign r `FSIGN = a `FSIGN;
assign r `FEXP = 253 + (!(a `FFRAC)) - a `FEXP;
assign r `FFRAC = look[a `FFRAC];
endmodule

module i2f(f, i);
output wire `FLOAT f;
input wire `INT i;
wire [4:0] lead;
wire `WORD pos;
assign pos = (i[15] ? (-i) : i);
lead0s m0(lead, pos);
assign f `FFRAC = (i ? ({pos, 8'b0} >> (16 - lead)) : 0);
assign f `FSIGN = i[15];
assign f `FEXP = (i ? (128 + (14 - lead)) : 0);
endmodule

// Float to integer conversion, 16 bit
// Note: out-of-range values go to -32768 or 32767
module f2i(i, f);
output wire `INT i;
input wire `FLOAT f;
wire `FLOAT ui;
wire tiny, big;
fslt m0(tiny, f, `F32768);
fslt m1(big, `F32767, f);
assign ui = {1'b1, f `FFRAC, 16'b0} >> ((128+22) - f `FEXP);
assign i = (tiny ? 0 : (big ? 32767 : (f `FSIGN ? (-ui) : ui)));
endmodule


module processor(halt, reset, clk);
    output reg halt;
    input reset, clk;

    reg `DATA r `REGS;	// register file
    reg `DATA dm `SIZE;	// data memory
    reg `INST im `SIZE;	// instruction memory
	reg `SIZE1624 lookup24 `MEMSIZE;	// Lookup table 16-24
	reg `SIZE840 lookup40 `MEMSIZE; 	// Lookup table 8->40
	
    reg `INST ir;
	reg `INST ir0;
    reg `STATE op0;
    reg `NIB head;		// current header (1st half of opcode)
    reg `REGNAME d0;	// destination register name
    reg `REGNAME s0; //source register name
    reg `DATA src;		// src value
    reg `DATA target;	// target for branch or jump
    reg `ADDR pc;
    reg `LOW8 imm;
	reg stage0_bz, stage0_bnz, stage0_jr;

    // Reset logic
    always @ (reset) begin
        halt = 0;
        pc = 0;
		ir = `NOP;
		ir0 = `NOP;
		ir1 = `NOP;
		ir2 = `NOP;
		ir3 = `NOP;
		stage0_jr = 0;
		stage0_bnz = 0;
		stage0_bz = 0;
		stage1_jr = 0;
		stage1_bnz = 0;
		stage1_bz = 0;
		rd2 = 0;
		op1 = 0;
		op2 = 0;
		res = 0;
		haltsignal = 0;
		
        $readmemh("vmem0.text",im); // Instruction memory
        $readmemh("vmem1.data",dm); // Data memory
		$readmemh("posit840.vmem",lookup40);	// lookup 8-40
		$readmemh("posit1624.vmem",lookup24);	// lookup 16-24
		
    end
    
	// Check for Trap
	function istrap;
	input `INST inst;
	istrap = ((inst `F_OP == `OPTRAP));
	endfunction
	
	function setsrd;
	input `INST inst;
	setsrd = ((inst `F_H != `OPBNZ) && (inst `F_H != `OPBZ) && (inst `F_OP != `OPJR) && (inst `F_OP != `OPST));
	endfunction
	
	function usesrs;
	input `INST inst;
	usesrs = (inst `F_OP != `OPANYI) && (inst `F_OP != `OPANYII) && (inst `F_H != `HBNZ) && (inst `F_H != `HBZ) && (inst `F_H != `HCI8) && (inst `F_H != `HCII) && (inst `F_H != `HCUP) && (inst `F_OP != `OPI2F) && (inst `F_OP != `OPII2PP) && (inst `F_OP != `OPINVF) && (inst `F_OP != `OPINVPP) && (inst `F_OP != `OPJR) && (inst `F_OP != `OPNEGI) && (inst `F_OP != `OPNEGII) && (inst `F_OP != `OPNOT) && (inst `F_OP != `OPF2I) && (inst `F_OP != `OPPP2II);
	endfunction
	
	reg haltsignal; // Signal to tell IF to never fetch anything new
	
    // 0. IF/ID Stage
    always @ (posedge clk) begin
	
		ir = im[pc];
		head = ir `F_H;
		
		//$display("IF stage: %d, %d", pc, wait1);
		// Check if new PC counter exists
		
		pc <= (wait1) ? (pc1) : (pc+1);
		//$display("PC: %d",pc);
		
		if (wait1) begin
		$display("Branch to %d",pc1);
		ir0 <= `NOP;
		op0 <= 255;
		end
		
		else begin
		// Check for Trap
		if ((haltsignal == 1) || (istrap(ir) && (ir1 `F_OP != `OPJR) && (ir1 `F_OP != `OPBZ) && (ir1 `F_OP != `OPBNZ) && (ir0 `F_OP != `OPJR) && (ir0 `F_OP != `OPBZ) && (ir0 `F_OP != `OPBNZ))) begin
			haltsignal <= 1;
			ir0 <= ir;
			op0 <= `OPTRAP;
		end
		
		else begin
		case(head)
			`HCI8: op0 <= `OPCI8;
			`HCII: op0 <= `OPCII;
			`HCUP: op0 <= `OPCUP;
			`HBNZ: op0 <= `OPBNZ;
			`HBZ: op0 <= `OPBZ;
			default: begin
				op0 <= ir `F_OP;
				s0 <= ir `F_S;
			end
			endcase
			
		//$display("JR: %d, BNZ: %d, BZ: %d",stage0_jr,stage0_bnz,stage0_bz);
		ir0 <= ir;
		end
		
		stage0_jr <= (ir `F_OP == `OPJR);
		stage0_bnz <= (ir `F_OP == `OPBNZ);
		stage0_bz <= (ir `F_OP == `OPBZ);
		
		end
		
	end
	
	
	reg `INST ir1;
	reg `STATE op1;
	reg `REGS rd1;
	reg `REGS rs1;
	reg `REGS rd;
	reg `REGS rs;
	reg stage1_bz, stage1_bnz, stage1_jr;
	reg wait1;
	reg [15:0] pc1;
	
	// lookup table registers, indexed in Read Stage
	reg [39:0] lookup40high;
	reg [39:0] lookup40low;
	reg [23:0] lookup24high;
	reg [23:0] lookup24low;
	wire [15:0] index1;
	wire [15:0] index2;
	
	//assign pc1 = (stage0_jr) ? (rd) : (pc + ir0 `F_C8);
	//assign wait1 = (stage1_bz) || (stage1_bnz) || (stage1_jr);
	
    // 1. Read Stage
    always @ (posedge clk) begin
	// Add the transfer of the immediate value
		
		pc1 <= (stage0_jr) ? (rd) : (pc - 1 + ir0 `F_C8);
		wait1 <= (stage0_bz) || (stage0_bnz) || (stage0_jr);
		stage1_jr <= stage0_jr;
		//$display("Read Stage OP: %x",op1);
		if (rd == 0 && stage0_bz) begin
		stage1_bz <= 1;
		stage1_bnz <= 0;
		ir1 <= `NOP;
		op1 <= 255;
		end else if (rd != 0 && stage0_bnz) begin
		stage1_bz <= 0;
		stage1_bnz <= 1;
		ir1 <= `NOP;
		op1 <= 255;
		end else begin
		stage1_bz <= 0;
		stage1_bnz <= 0;
		ir1 <= ir0;
		op1 <= op0;
		end
		
		//$display("Read stage: %d, RD: %h, RS: %h", pc, ir0 `F_D, ir0 `F_S);
		if (wait1) begin
		$display("Waiting...");
			ir1 <= `NOP;
			op1 <= `NOP;
		end
		
		else begin
		
		if (Ex_to_Rd_Signal == 1) begin
			//$display("Ex Forward Rd on %d: %h",ir0 `F_D,Ex_to_Read);
			//$display("Res @ time: %h",res);
			rd = Ex_to_Read;
		end
		else if (WB_to_Rd_Signal == 1) begin
			//$display("WB Forward Rd on %d: %h",ir0 `F_D,WB_to_Read);
			//$display("Res @ time: %h",res);
			rd = WB_to_Read;
		end
		else begin
			rd = r[ir0 `F_D];
		end
		
		
		if (Ex_to_Rs_Signal == 1) begin
			//$display("Ex Forward Rs on %d: %h",ir0 `F_S,Ex_to_Read);
			//$display("Res @ time: %h",res);
			rs = Ex_to_Read;
		end 
		else if (WB_to_Rs_Signal == 1) begin
			//$display("WB Forward Rs on %d: %h",ir0 `F_D,WB_to_Read);
			//$display("Res @ time: %h",res);
			rs = WB_to_Read;
		end
		else begin
			rs = r[ir0 `F_S];
		end
		
		// 8 bit posit = input
		// look40 = upper
		// look40 = lower
		// 2 indexes (fits)
		
		
		
		// 16 bit p,p or float = input
		// look24 = upper
		// look24 = lower
		// 2 indexes (fits)
		//if (ir0 `F_OP != `OPF2PP) begin
		//	index1 = {rd`LO8,rs`LO8};
		//	$display("%h, %h",rd,rs);
		//	index2 = {rd`HI8,rs`HI8};
		//end
		//else begin
		//	index1 = rd;
		//	index2 = 0;
		//end
		rd1 <= rd;
		rs1 <= rs;
		end
    end

	
	reg `INST ir2;
	reg `REGS rd2;	// Register data
	//reg `REGS rs2;	// Register data
	reg `STATE op2;
	reg `WORD res;
	wire `WORD resi2f, resf2i, resaddf, resmulf, resinvf;
	wire Ex_to_Rd_Signal;
	wire Ex_to_Rs_Signal;
	wire [15:0] Ex_to_Read;
	
	assign Ex_to_Rd_Signal = (ir1 `F_D == ir0 `F_D) && (ir1 != `NOP && ir0 != `NOP) && setsrd(ir1);
	assign Ex_to_Rs_Signal = (ir1 `F_D == ir0 `F_S) && (ir1 != `NOP && ir0 != `NOP) && setsrd(ir1);
	assign Ex_to_Read = res;
	
	
	i2f i2f(resi2f,rd1);
	f2i f2i(resf2i,rd1);
	fadd fadd(resaddf,rd1,rs1);
	fmul fmul(resmulf,rd1,rs1);
	frecip frecip(resinvf,rd1);
	
	assign index1 = (ir1 `F_OP != `OPF2PP) ? ({rd1`LO8,rs1`LO8}) : (rd1);
	assign index2 = (ir1 `F_OP != `OPF2PP) ? ({rd1`HI8,rs1`HI8}) : (0);
	// Always without pos/neg edge???
	// Or straight combinatorial
	always @ (negedge clk) begin
		
		lookup40low = lookup40[rd1`LO8];
		lookup40high = lookup40[rd1`HI8];
	
		//$display("Index1: %h, %h",index1,rd1);
		//$display("Index2: %h, %h",index2,rs1);
		
		lookup24low = lookup24[index1];
		//$display("Lookuplow: %h",lookup24low);
		lookup24high = lookup24[index2];
		//$display("Lookuphigh: %h",lookup24high);
	
	
	case(op1)
            `OPCI8: begin
                res = ir1 `F_C8;
                if(ir1[11:11] == 1)
                    res `HI8 = 255;
                else
                    res `HI8 = 0;
				$display("OPCI8: %d, %d, %h",ir1 `F_D,ir1 `F_ADDR, res);
                end
            `OPCII: begin
                res = ir1 `F_C8;
                res `HI8 = ir1 `F_C8;
				$display("OPCII: %d, %d, %h",ir1 `F_D,ir1 `F_ADDR, res);
                end
			`OPCUP: begin
				res`LO8 = rd1`LO8;
				res`HI8 = ir1 `F_C8;
				$display("CUP: $%d = %H", ir1 `F_D, res);
				end
            `OPADDI: begin
			res = rd1 + rs1;
			$display("OPADDI: %d: %h, %d: %h, %h",ir1 `F_D,rd1,ir1 `F_S,rs1, res);
			end
            `OPADDII: begin
                res = rd1 + rs1;
                res `HI8 = rd1 `HI8 + rs1 `HI8;
				$display("OPADDII: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
                end
			`OPADDPP: begin
				res`LO8 = lookup24low[23:16];
				res`HI8 = lookup24high[23:16];
				$display("OPADDPP: %d, %d, %h",ir1 `F_D, ir1 `F_S, res);
			end
            `OPMULI, `OPMULF: begin
			res = rd1 * rs1;
			$display("OPMULI/P: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPMULII: begin
                res = rd1 * rs1;
                res `HI8 = rd1 `HI8 * rs1 `HI8;
				$display("OPMULII: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
                end
			`OPMULPP: begin
				res`LO8 = lookup24low[15:8];
				res`HI8 = lookup24high[15:8];
				$display("OPMULPP: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPSHI: begin
			res = (rs1 > 32767 ? rd1 >> -rs1 : rd1 << rs1);
			$display("OPSHI: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPSHII: begin
                res `LOW8 = (rs1 `LOW8 > 127 ? rd1 `LOW8 >> -rs1 `LOW8 : rd1 `LOW8 << rs1 `LOW8);
                res `HI8 = (rs1 `HI8 > 127 ? rd1 `HI8 >> -rs1 `HI8 : rd1 `HI8 << rs1 `HI8);
				$display("OPSHII: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
                end
            `OPAND: begin
			res = rd1 & rs1;
			$display("OPAND: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPOR: begin
			res = rd1 | rs1;
			$display("OPOR: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPXOR: begin
			res = rd1 ^ rs1;
			$display("OPXOR: %d, %d, %h",ir1 `F_D,ir1 `F_S, res);
			end
            `OPNOT: begin
			res = ~rd1;
			$display("OPNOT: %d, %h",ir1 `F_D, res);
			end
            `OPANYI: begin
			res = (rd1 ? -1 : 0);
			$display("OPANYI: %d, %h",ir1 `F_D, res);
			end
            `OPANYII: begin
                res `HI8 = (rd1 `HI8 ? -1 : 0);
                res `LOW8 = (rd1 `LOW8 ? -1 : 0);
				$display("OPANYII: %d, %h",ir1 `F_D, res);
                end
            `OPNEGI: begin 
			res = -rd1;
			$display("OPNEGI: %d, %h",ir1 `F_D, res);
			end
            `OPNEGII: begin
                res `HI8 = -rd1 `HI8;
			    res `LOW8 = -rd1 `LOW8;
				$display("OPNEGII: %d, %h",ir1 `F_D, res);
                end
            `OPST: begin
			dm[rs1] = rd1;
			$display("OPST: %d",ir1 `F_D);
			end
            `OPLD: begin
			res = dm[rs1];
			$display("OPLD: %d",ir1 `F_D);
			end
			`OPSLTI: begin
			res = rd1 < rs1;
			$display("OPSLTI: %d, %d, %h",ir1 `F_D, ir1 `F_S, res);
			end
			`OPSLTII: begin 
                res `HIGH8 = rd1 `HIGH8 < rs1 `HIGH8; 
			    res `LOW8 = rd1 `LOW8 < rs1 `LOW8;
				$display("OPSLTII: %d, %d, %h",ir1 `F_D, ir1 `F_S, res);
                end
			`OPII2PP: begin
				res `HI8 = lookup40high[7:0];
				res `LO8 = lookup40low[7:0];
				$display("OPII2PP: $%d, %h", ir1 `F_D, res);
				end
			`OPPP2II: begin
				res `HI8 = lookup40high[15:8];
				res `LO8 = lookup40low[15:8];
				$display("OPPP2II: $%d, %h", ir1 `F_D, res);
				end
			`OPINVPP: begin 
				res`HI8 = lookup40high[39:32];
				res`LO8 = lookup40low[39:32];
				$display("OPINVPP: $%d, %h", ir1 `F_D, res);
				end
			`OPF2PP: begin
				res`LO8 = lookup24low[7:0];
				res`HI8 = lookup24low[7:0];
				$display("OPF2PP: $%d, %h", ir1 `F_D, res);
				end
			`OPPP2F: begin
				res = lookup40low[31:16];
				$display("OPPP2F: $%d, %h", ir1 `F_D, res);
				end
			`OPDUP: begin
				res = rs1;
				$display("OPDUP: %d, %d, %h",ir1 `F_D, ir1 `F_S, res);
				end
			`OPNEGF: begin
				res = {rd1^16'h8000};
				$display("OPNEGF: %d, %h", ir1 `F_D, res);
				end
			`OPI2F: begin
				res = resi2f;
				$display("OPI2F: %d, %h", ir1 `F_D, res);
			end
			`OPF2I: begin
				res = resf2i;
				$display("OPF2I: %d, %h", ir1 `F_D, res);
			end
			`OPINVF: begin
				res = resinvf;
				$display("OPINVF: %d, %h", ir1 `F_D, res);
			end
			`OPADDF: begin
				res = resaddf;
				$display("OPADDF: %d, %d, %h", ir1 `F_D, ir1 `F_S, res);
			end
			`OPMULF: begin
				res = resmulf;
				$display("OPMULF: %d, %d, %h", ir1 `F_D, ir1 `F_S, res);
			end
			
            default: begin
			res = rd1;
			//$display("Default?");
			end
        endcase
		end
		
	// Ex Stage
	always @ (posedge clk) begin
		
	//$display("Ex stage: %d, %h, %h, %h, %h", pc, ir1, op1, rs1, rd1);
	
		ir2 <= ir1;
		if (ir1 != `NOP && ir1 `F_OP != `OPTRAP) begin
		//$display("Res Taken");
		rd2 <= res;
		end
	end
	
	reg `INST ir3;
	reg `REGS rd3;	// Register data
	wire WB_to_Rd_Signal;
	wire WB_to_Rs_Signal;
	wire [15:0] WB_to_Read;
	
	assign WB_to_Rd_Signal = (ir2 `F_D == ir0 `F_D) && (ir2 != `NOP && ir0 != `NOP) && setsrd(ir2);
	assign WB_to_Rs_Signal = (ir2 `F_D == ir0 `F_S) && (ir2 != `NOP && ir0 != `NOP) && setsrd(ir2);
	assign WB_to_Read = rd2;
	
    // 3. WB Stage
	always @ (posedge clk) begin
	
	//$display("WB stage: %d", pc);
		ir3 <= ir2;
		rd3 <= rd2;
		if (setsrd(ir2) && ir2 != `NOP) begin
			r[ir2 `F_D] <= rd2;
			//$display("WB: %h to %d", rd2,ir2 `F_D);
		end
		
		if (istrap(ir2)) begin
		halt <= 1;
		end
		
	end

endmodule


module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
//$dumpfile;
//$dumpvars(0, PE);
  #10 reset = 1;
  #10 clk = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 0;
	$display("------- Clock--------");
    #10 clk = 1;
  end
  $finish;
end
endmodule