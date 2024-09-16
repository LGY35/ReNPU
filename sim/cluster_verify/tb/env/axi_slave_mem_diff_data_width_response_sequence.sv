
/**
 * Abstract:
 * axi_slave_mem_diff_data_width_response_sequence extended from axi_slave_mem_response_sequence
   is used by test to provide information to the Slave agent present in the System Env.
 * This class defines a sequence in which a write is followed by read using the
   write_byte API and read_byte_API respectively.
 * 
 * Execution phase: main_phase
 * Sequencer: Slave agent sequencer
 */

`ifndef GUARD_AXI_SLAVE_MEM_DIFF_DATA_WIDTH_RESPONSE_SEQUENCE_SV
`define GUARD_AXI_SLAVE_MEM_DIFF_DATA_WIDTH_RESPONSE_SEQUENCE_SV

class axi_slave_mem_diff_data_width_response_sequence extends axi_slave_mem_response_sequence;

  svt_axi_slave_agent slave_agt;

  bit[`SVT_AXI_MAX_ADDR_WIDTH-1:0] addr_l;
  bit[`SVT_AXI_MAX_ADDR_WIDTH-1:0] addr_t;
  bit[7:0] data;
  bit[7:0] data_t;
  bit [127:0]datain[127:0];
  /** UVM Object Utility macro */
  `uvm_object_utils(axi_slave_mem_diff_data_width_response_sequence)

  /** Class Constructor */
  function new(string name="axi_slave_mem_diff_data_width_response_sequence");
    super.new(name);
  endfunction
  
  extern task dma_drive();
  extern function axi_write_mem128(string name,bit[31:0] address,logic [127:0] data);
  
  virtual task body();

  integer fp,i;
    `uvm_info("body", "Entered ...", UVM_LOW)

    $cast(slave_agt, p_sequencer.get_parent()); 

    fp = $fopen("/home/zhangshiwei/project/cluster_verify/test/instr_data.txt","r");
        for(i=0;i<128;i++) begin
               $fscanf(fp,"%h",datain[i]);
               $display("$fscanf instr data%d: %h",i,datain[i]);
        end

    //write using write_byte API. 
    for(int i=0;i<32;i++) begin
      addr_l=92000000+i; 
      data = i + 8;
      slave_agt.write_byte(addr_l, data); 
      `svt_xvm_debug("body", $sformatf("Writing to address %0h data is %0h using write_byte_API",addr_l,data));
    end

    //read using read_byte API. 
    for(int i=0;i<32;i++) begin
      addr_l=92000000+i; 
      slave_agt.read_byte(addr_l, data); 
      `svt_xvm_debug("body", $sformatf("Reading from address %0h data is %0h using read_byte_API",addr_l,data));
    end


     for (int j=0;j<128;j++) begin
        for(int i=0;i<16;i++) begin
            addr_t = (j*16) + i ;
            data_t = datain [j] [(8*i) +: 8];
            slave_agt.write_byte(addr_t,data_t);
        `uvm_info("body", $sformatf("mem init addr=%0h  data=%0h",addr_t,data_t), UVM_LOW)
        end 
     end

    `uvm_info("body", "mem init addr='h2000", UVM_LOW)
    super.body(); 

    `uvm_info("body", "Exiting...", UVM_LOW)
  endtask: body

endclass: axi_slave_mem_diff_data_width_response_sequence

task dma_drive();
endtask

function axi_write_mem128(string name,bit[31:0] address,logic [127:0] data);

endfunction


`endif // GUARD_AXI_SLAVE_MEM_DIFF_DATA_WIDTH_RESPONSE_SEQUENCE_SV
