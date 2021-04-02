{%- import 'addressable.sv' as addressable with context -%}

// This file was autogenerated by PeakRDL-verilog
module {{get_inst_name(top_node)}} #(
    parameter                                ADDR_OFFSET = {{top_node.absolute_address}},  // Module's offset in the main address map
    parameter                                ADDR_WIDTH  = 32,   // Width of SW address bus
    parameter                                DATA_WIDTH  = 32    // Width of SW data bus
)(
    // Clocks and resets
    input logic                              clk,
    input logic                              resetn,

{%- for node in top_node.descendants() -%}
{%- if isinstance(node, RegNode) %}

    // Register {{get_inst_name(node).upper()}}
    output logic {{node.full_array_ranges}}        {{signal(node)}}_strb,

{%- elif isinstance(node, FieldNode) -%}
{%- if node.is_hw_writable %}
    input  logic {{node.parent.full_array_ranges}}        {{signal(node)}}_wr,
    input  logic {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node)}}_wdata,

{%- endif -%}
{%- if node.is_hw_readable %}
    output logic {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node)}}_q,

{%- endif -%}
{%- if node.is_up_counter and not node.get_property('incr') %}
    input  logic {{node.parent.full_array_ranges}}        {{signal(node)}}_incr,
    {%- if node.get_property('incrwidth') %}
    input  logic {{node.parent.full_array_ranges}}[{{node.get_property('incrwidth')}}-1:0] {{signal(node)}}_incrvalue,
    {%- endif -%}
{%- endif -%}
{%- if node.is_down_counter and not node.get_property('decr') %}
    input  logic {{node.parent.full_array_ranges}}        {{signal(node)}}_decr,
    {%- if node.get_property('decrwidth') %}
    input  logic {{node.parent.full_array_ranges}}[{{node.get_property('decrwidth')}}-1:0] {{signal(node)}}_decrvalue,
    {%- endif -%}
{%- endif -%}
{%- endif -%}
{%- endfor %}

    // Register Bus
    input  logic                             valid,    // active high
    input  logic                             read,     // indicates request is a read
    input  logic            [ADDR_WIDTH-1:0] addr,     // address (byte aligned, absolute address)
    input  logic            [DATA_WIDTH-1:0] wdata,    // write data
    input  logic          [DATA_WIDTH/8-1:0] wmask,    // write mask
    output logic            [DATA_WIDTH-1:0] rdata     // read data
);

    // local signals for fields
{%- for node in top_node.descendants() -%}
{%- if isinstance(node, FieldNode) -%}
{%- if not node.is_hw_readable %}
    logic       {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node)}}_q;
{%- endif -%}
{%- if node.is_up_counter %}
    logic {{node.parent.full_array_ranges}}        {{signal(node)}}_overflow;
{%- endif -%}
{%- if node.is_down_counter %}
    logic {{node.parent.full_array_ranges}}        {{signal(node)}}_underflow;
{%- endif -%}
{%- endif -%}
{%- endfor %}

    // ============================================================
    // SW Access logic
    // ============================================================

    logic [DATA_WIDTH-1:0] mask;

    always @ (wmask) begin
        int byte_idx;
        for (byte_idx = 0; byte_idx < DATA_WIDTH/8; byte_idx+=1)
          mask[8*(byte_idx+1)-1 -: 8] = {8{wmask[byte_idx]}};
    end

{%- for node in top_node.descendants() -%}
{%- if isinstance(node, RegNode) %}
    logic {{node.full_array_ranges}}[DATA_WIDTH-1:0] {{signal(node)}}_rdata;
{%- endif -%}
{%- endfor %}

    assign rdata = // or of each register return (masked)
{%- for node in top_node.descendants() -%}
    {%- if isinstance(node, RegNode) %}
        {%- for idx in node.full_array_indexes %}
                   {{signal(node)}}_rdata{{idx}} |
        {%- endfor -%}
    {%- endif -%}
{%- endfor %}
                   {DATA_WIDTH{1'b0}};

    {{ addressable.body(top_node)|indent}}

endmodule: {{get_inst_name(top_node)}}

