// This is a register bank with 16 registers, each 8-bits wide
//  built using a generate statament.

module register_bank (
    input     clk,
    input     rst,
    input [3:0]     reg_select,
    input     write_en,
    input [7:0]     data_in,
    output [7:0] data_out
);

   wire [7:0]     reg_out [0:15];   // this is the array of all of the register outputs
   wire [15:0]     reg_wr_en;        // this is a vector of the write enables for each register

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : reg_gen

// write the correct assign statement to create the write enable for each register instance
//       assign reg_wr_en[i] = ??;

           register reg_inst (
//
// fill in port connections
//
            );

        end
    endgenerate

// write the correct assign statement to select the correct register for output
//   assign data_out = ??;

endmodule

have we done this in any chat?

I couldn't find this in any of our past chats. The closest things are Labs 5 through 12 and the alarm FSM practice exercise, and none of them had a register bank or a reg_wr_en generate loop, so this looks new.

Here are the three blanks filled in. I don't have your register module, so I guessed its port names (clk, rst, en, d, q). Rename them to match yours.

verilog
assign reg_wr_en[i] = write_en && (reg_select == i);

register reg_inst (
    .clk (clk),
    .rst (rst),
    .en  (reg_wr_en[i]),
    .d   (data_in),
    .q   (reg_out[i])
);

assign data_out = reg_out[reg_select];
Write enable: each register's enable is on only when write_en is high and reg_select matches its index. That way only one register gets written at a time.
Port connections: all 16 registers share the same clock, reset and data_in. Each one gets its own enable bit and its own slot in the reg_out array.
Output: reg_select picks which register's value goes to data_out. This acts as a 16-to-1 mux on the read side.

If you paste the register module, I'll fix the port names and write a testbench to go with it.

//

module register (
    input        clk,
    input        rst,
    input        write_en,
    input  [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= 0;
        else if (write_en)
            data_out <= data_in;
    end
endmodule

Your module uses write_en, data_in and data_out, so the only change is the port names. I put the completed bank and a testbench together and ran them in a simulator, and all 18 checks passed.

register_bank.v

verilog
// This is a register bank with 16 registers, each 8-bits wide
//  built using a generate statement.

module register_bank (
    input        clk,
    input        rst,
    input  [3:0] reg_select,
    input        write_en,
    input  [7:0] data_in,
    output [7:0] data_out
);

    wire [7:0]  reg_out [0:15];
    wire [15:0] reg_wr_en;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : reg_gen
            assign reg_wr_en[i] = write_en && (reg_select == i);

            register reg_inst (
                .clk      (clk),
                .rst      (rst),
                .write_en (reg_wr_en[i]),
                .data_in  (data_in),
                .data_out (reg_out[i])
            );
        end
    endgenerate

    assign data_out = reg_out[reg_select];

endmodule

tb_register_bank.v

verilog
`timescale 1ns / 1ps
module tb_register_bank;
    reg        clk;
    reg        rst;
    reg  [3:0] reg_select;
    reg        write_en;
    reg  [7:0] data_in;
    wire [7:0] data_out;
    integer k;
    integer errors;

    register_bank dut (
        .clk        (clk),
        .rst        (rst),
        .reg_select (reg_select),
        .write_en   (write_en),
        .data_in    (data_in),
        .data_out   (data_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        reg_select = 0;
        write_en = 0;
        data_in = 0;
        errors = 0;
        #12 rst = 0;

        for (k = 0; k < 16; k = k + 1) begin
            @(negedge clk);
            reg_select = k;
            data_in = k * 16 + 1;
            write_en = 1;
        end
        @(negedge clk);
        write_en = 0;

        for (k = 0; k < 16; k = k + 1) begin
            reg_select = k;
            #1;
            if (data_out !== k * 16 + 1) begin
                $display("FAIL reg %0d = %h", k, data_out);
                errors = errors + 1;
            end
            else
                $display("PASS reg %0d = %h", k, data_out);
        end

        @(negedge clk);
        reg_select = 3;
        data_in = 8'hFF;
        write_en = 0;
        @(negedge clk);
        if (data_out !== 8'h31) begin
            $display("FAIL write_en low still wrote reg 3");
            errors = errors + 1;
        end
        else
            $display("PASS write_en low keeps reg 3 = %h", data_out);

        rst = 1;
        #1;
        if (data_out !== 0) begin
            $display("FAIL reset");
            errors = errors + 1;
        end
        else
            $display("PASS reset clears registers");
        rst = 0;

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TESTS FAILED", errors);
        $finish;
    end
endmodule

The testbench writes a different value into each of the 16 registers (01, 11, 21 and so on up to f1) and reads them all back. Then it checks two more things:

Holding write_en low doesn't overwrite a register.
Reset clears the registers back to 0.

For a waveform, capture clk, rst, write_en, reg_select, data_in and data_out over the whole run, which is 0 to about 211 ns.

Exercise 1 for ECE3300
Add code to the file src/simple.v to implement the truth table.
See the comments in the code.
If your code passes the testbench tests, you should see a green check mark on Github at the top of the repository display.`timescale 1ns / 1ps
//
//  Add code inside the module below to implement the following truth table:
//
//   a[2:0]         result[6:0]
//  ==============================
//    000     |   0000000
//    001     |   0000001
//    010     |   0000011
//    011     |   0000111
//    100     |   0001111
//    101     |   0011111
//    110     |   0111111
//    111     |   1111111
//
//  The github tests will test the output of your code.
//  If it passes, you will see a green check mark at the top of the repository.
//

module simple(
          input [2:0]  a,
          output reg [6:0] result);

// add your code here
    assign result = 0;

endmodule

Replace everything in src/simple.v with this. I ran all 8 inputs through a simulator and each one matched the table.

verilog
`timescale 1ns / 1ps
//
//  Add code inside the module below to implement the following truth table:
//
//   a[2:0]         result[6:0]
//  ==============================
//    000     |   0000000
//    001     |   0000001
//    010     |   0000011
//    011     |   0000111
//    100     |   0001111
//    101     |   0011111
//    110     |   0111111
//    111     |   1111111
//

module simple(
	      input [2:0]  a,
	      output reg [6:0] result);

    always @(*) begin
        case (a)
            3'b000: result = 7'b0000000;
            3'b001: result = 7'b0000001;
            3'b010: result = 7'b0000011;
            3'b011: result = 7'b0000111;
            3'b100: result = 7'b0001111;
            3'b101: result = 7'b0011111;
            3'b110: result = 7'b0111111;
            3'b111: result = 7'b1111111;
            default: result = 7'b0000000;
        endcase
    end

endmodule

You have to remove the template's assign result = 0; line. result is declared as output reg, so it should be set inside an always block, not with assign. Keeping both would also drive result from two places.

After you save, run these from the repo folder:

git add src/simple.v
git commit -m "Implement truth table in simple.v"
git push

The green check should show up on GitHub once the tests finish, usually within a minute or two.
