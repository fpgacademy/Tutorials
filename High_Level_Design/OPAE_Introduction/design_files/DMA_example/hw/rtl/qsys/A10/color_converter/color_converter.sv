module color_converter(clk, reset, s0_write, s0_writedata, s0_address, s0_read, s0_readdata,
    readdata, readdatavalid, waitrequest, address, read, write, writedata);

parameter NUM_BYTES = 64, n = 512;

input clk, reset, s0_write, s0_read;
input [63:0] s0_writedata;
output logic [63:0] s0_readdata;
input s0_address;

input [n-1:0] readdata;
input readdatavalid, waitrequest;

output logic [47:0] address;
output logic read, write;
output logic [n-1:0] writedata;


logic convert_done;
logic [31:0] pixel_counter;
logic [47:0] src_address, dst_address;
logic [n*3-1:0] data;


logic convert_en;

wire ctrl, ctrl_address;
wire [63:0] ctrl_data;

assign ctrl = s0_write;
assign ctrl_data = s0_writedata;
assign ctrl_address = s0_address;


always @(posedge clk) begin
    if(reset)
        s0_readdata <= '0;
    else if(s0_read)begin
        if(s0_address == 0) 
            s0_readdata <=  {16'h0, dst_address};
        else if(s0_address == 1)
            s0_readdata <= {63'h0, convert_done};
    end
end


// read instruction
always @(posedge clk) begin
    if(reset) begin
        src_address <= '0;
        dst_address <= '0;
    end
    else if(ctrl && ctrl_address == 0) begin
        src_address <= '0;
        dst_address <= ctrl_data[47:0];
    end
end

always @(posedge clk) begin
    if(reset)
        convert_done <= 1'b0;
    else if(pixel_counter > 0 && pixel_counter == dst_address)
        convert_done <= 1'b1;
    else if(ctrl && ctrl_address == 0)     // new instruction arrives
        convert_done <= 1'b0;
end

always @(posedge clk) begin
    if(reset)
        convert_en <= 1'b0;
    else if(ctrl && ctrl_address == 0) // convert start
        convert_en <= 1'b1;
    else if(convert_done == 1)
        convert_en <= 1'b0;  
end


genvar i;

generate
    for(i = 0; i < NUM_BYTES; i= i+1)begin : gen_read_data
        always@(posedge clk) begin
            if(reset)
                data[((i*3) << 3) + 23 :( (i*3) << 3)] <= 8'b0;
            else if(readdatavalid) begin
                data[((i*3) << 3) + 7 :((i*3) << 3)] <= readdata[(i << 3) + 7 :(i << 3)];
                data[((i*3 + 1) << 3) + 7 :((i*3 + 1) << 3)] <= readdata[(i << 3) + 7 :(i << 3)];
                data[((i*3 + 2) << 3) + 7 :((i*3 + 2) << 3)] <= readdata[(i << 3) + 7 :(i << 3)];
            end
        end //end always 
    end
endgenerate


localparam STATE_0_IDLE = 4'h0,
            STATE_1_READ = 4'h1,
            STATE_2_READ_REQ = 4'h2, // the cycle when read is high
            STATE_3_READ_WAIT = 4'h3,
            STATE_4_WRITE = 4'h4,
            STATE_5_WRITE_REQ = 4'h5,
            STATE_6_WRITE_1 = 4'h6,
            STATE_7_WRITE_REQ_1 = 4'h7,
            STATE_8_WRITE_2 = 4'h8,
            STATE_9_WRITE_REQ_2 = 4'h9,
            STATE_10_COUNT = 4'ha;
    
logic [3:0] convert_state;
logic [3:0] convert_state_next;

always @(posedge clk) begin
    if(reset)
        convert_state <= STATE_0_IDLE;
    else
        convert_state <= convert_state_next;
end

always @(*) begin
    if(reset)
        convert_state_next <= STATE_0_IDLE;
    else if(!convert_en)
        convert_state_next <= STATE_0_IDLE;
    else begin
        case(convert_state)
            STATE_0_IDLE:
                begin
                    if(convert_en)
                        convert_state_next = STATE_1_READ;
                    else
                        convert_state_next = STATE_0_IDLE;
                end
             STATE_1_READ:
                begin
                    convert_state_next = STATE_2_READ_REQ;
                end
            STATE_2_READ_REQ:
                begin
                    if(waitrequest)
                        convert_state_next = STATE_2_READ_REQ;
                    else
                        convert_state_next = STATE_3_READ_WAIT;
                end
            STATE_3_READ_WAIT:
                begin
                    if(readdatavalid)
                        convert_state_next = STATE_4_WRITE;
                    else
                        convert_state_next = STATE_3_READ_WAIT;
                end
            STATE_4_WRITE:
                begin
                    convert_state_next = STATE_5_WRITE_REQ;
                end
            STATE_5_WRITE_REQ:
                begin
                    if(waitrequest)
                        convert_state_next = STATE_5_WRITE_REQ;
                    else
                        convert_state_next = STATE_6_WRITE_1;
                end
            STATE_6_WRITE_1:
                begin
                    convert_state_next = STATE_7_WRITE_REQ_1;
                end
            STATE_7_WRITE_REQ_1:
                begin
                    if(waitrequest)
                        convert_state_next = STATE_7_WRITE_REQ_1;
                    else
                        convert_state_next = STATE_8_WRITE_2;
                end
            STATE_8_WRITE_2:
                begin
                    convert_state_next = STATE_9_WRITE_REQ_2;
                end
            STATE_9_WRITE_REQ_2:
                begin
                    if(waitrequest)
                        convert_state_next = STATE_9_WRITE_REQ_2;
                    else
                        convert_state_next = STATE_10_COUNT;
                end
            STATE_10_COUNT:
                begin
                    if(convert_en)
                        convert_state_next = STATE_1_READ;
                    else
                        convert_state_next = STATE_0_IDLE;
                end
            default:
                begin
                    convert_state_next = STATE_0_IDLE;
                end
        endcase
    end
end 


always @(posedge clk) begin
    if(reset) begin
        pixel_counter <= '0;
        address <= '0;
        read <= 1'b0;
        write <= 1'b0;
        writedata <= '0;
    end
    else begin
        case(convert_state)
            STATE_0_IDLE:
                begin
                    read <= 1'b0;
                    write <= 1'b0;
                end
            STATE_1_READ:
                begin
                    address <= src_address + pixel_counter;
                    read <= 1'b1;
                    write <= 1'b0;
                end
            STATE_2_READ_REQ:
                begin
                    address <= src_address + pixel_counter;
                    read <= 1'b1;
                    write <= 1'b0;
                end
            STATE_3_READ_WAIT:
                begin
                    read <= 1'b0;
                    write <= 1'b0;
                end
            STATE_4_WRITE:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter; // pixel_counter * 3
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[n-1:0];
                end
            STATE_5_WRITE_REQ:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter;
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[n-1:0];
                end
             STATE_6_WRITE_1:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter + NUM_BYTES; // pixel_counter * 3 + 64
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[(n << 1) -1:n]; // 2n-1:n
                end
            STATE_7_WRITE_REQ_1:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter + NUM_BYTES;
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[(n << 1) -1:n];
                end
             STATE_8_WRITE_2:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter + (NUM_BYTES << 1); // pixel_counter * 3 + 128
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[ (n << 1) + n-1: (n << 1)]; // 3n-1:2n
                end
            STATE_9_WRITE_REQ_2:
                begin
                    address <= dst_address + (pixel_counter << 1) + pixel_counter + (NUM_BYTES << 1);
                    read <= 1'b0;
                    write <= 1'b1;
                    writedata <= data[ (n << 1) + n-1: (n << 1)];
                end
            STATE_10_COUNT:
                begin
                    read <= 1'b0;
                    write <= 1'b0;
                    pixel_counter <= pixel_counter + NUM_BYTES;
                end
            default:
                begin
                    address <= '0;
                    read <= 1'b0;
                    write <= 1'b0;
                    writedata <= '0;
                end
            endcase
        end // end else
    end //end always
endmodule