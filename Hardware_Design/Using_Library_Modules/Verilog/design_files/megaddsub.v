// Adder/subtractor module created by the MegaWizard
module megaddsub (
    add_sub,
    dataa,
    datab,
    overflow,
    result);

input add_sub;
input [15:0] dataa;
input [15:0] datab;
output overflow;
output [15:0] result;
wire sub_wire0;
wire [15:0] sub_wire1;
wire overflow = sub_wire0;
wire [15:0] result = sub_wire1[15:0];

lpm_add_sub lpm_add_sub_component (
    .dataa (dataa),
    .add_sub (add_sub),
    .datab (datab),
    .overflow (sub_wire0),
    .result (sub_wire1));
defparam
    lpm_add_sub_component.lpm_direction = "UNUSED",
    lpm_add_sub_component.lpm_hint = "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO",
    lpm_add_sub_component.lpm_representation = "SIGNED",
    lpm_add_sub_component.lpm_type = "LPM_ADD_SUB",
    lpm_add_sub_component.lpm_width = 16;
endmodule
