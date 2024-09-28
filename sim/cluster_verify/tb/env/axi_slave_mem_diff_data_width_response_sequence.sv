
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
  bit [7:0]instr_in[511:0];
  bit [255:0]data_in[0:511];
  /** UVM Object Utility macro */
  `uvm_object_utils(axi_slave_mem_diff_data_width_response_sequence)

  /** Class Constructor */
  function new(string name="axi_slave_mem_diff_data_width_response_sequence");
    super.new(name);
  endfunction
  
  extern task dma_drive();
  extern function axi_write_mem128(string name,bit[31:0] address,logic [127:0] data);
  
  virtual task body();

  integer fp,i,fp1;
    `uvm_info("body", "Entered ...", UVM_LOW)

    $cast(slave_agt, p_sequencer.get_parent()); 

    fp = $fopen("../../test/DVcase/case1_dmawr/case1_instr.txt","r");
        for(i=0;i<512;i++) begin
               $fscanf(fp,"%h",instr_in[i]);
               $display("$fscanf instr data%d: %h",i,instr_in[i]);
        end

    fp1 = $fopen("../../test/DVcase/case1_dmawr/case1_data.txt","r");
        for(i=0;i<512;i++) begin
               $fscanf(fp1,"%h",data_in[i]);
               $display("$fscanf test data%d: %h",i,data_in[i]);
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


     //for (int j=0;j<512;j++) begin
     //   for(int i=0;i<4;i++) begin
     //       addr_t = (j*4) + i ;
     //       data_t = instr_in [j] [(8*i) +: 8];
     //       slave_agt.write_byte(addr_t,data_t);
     //   `uvm_info("body", $sformatf("mem init addr=%0h  data=%0h",addr_t,data_t), UVM_LOW)
     //   end 
     //end

     for (int j=0;j<512;j++) begin
            addr_t = j ;
            data_t = instr_in [j];
            slave_agt.write_byte(addr_t,data_t);
        `uvm_info("body", $sformatf("mem init addr=%0h  data=%0h",addr_t,data_t), UVM_LOW) 
     end

     for (int j=0;j<512;j++) begin
        for(int i=0;i<32;i++) begin
            addr_t = (j*32) + i + 512;
            data_t = data_in [j] [(8*i) +: 8];
            slave_agt.write_byte(addr_t,data_t);
        `uvm_info("body", $sformatf("mem data addr=%0h  data=%0h",addr_t,data_t), UVM_LOW)
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
