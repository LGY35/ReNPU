// 管理向L2 RAM的写入和读出
module addr_mu_ns(
    input                               clk,
    input                               rst_n,

    input               [12:0]          cfg_base_addr,
    input               [3:0][12:0]     cfg_gap,
    input               [3:0][12:0]     cfg_lenth,

    input                               addr_mu_initial_en, //第一次启动一下，后面就内部自动执行完了
    input                               addr_mu_valid,  

    // output  logic       [17:0]      addr_mu_addr_ns,
    output  logic       [12:0]          addr_mu_addr
);

logic [12:0] base_addr;
logic [3:0][12:0] loop_cnt, loop_cnt_ns;
logic [3:0][12:0] loop_addr, loop_addr_ns;
logic [3:0] loop_target;
logic [12:0] addr_mu_addr_ns;

assign loop_target[0] = (loop_cnt[0] == cfg_lenth[0]);
assign loop_target[1] = (loop_cnt[1] == cfg_lenth[1]);
assign loop_target[2] = (loop_cnt[2] == cfg_lenth[2]);
assign loop_target[3] = (loop_cnt[3] == cfg_lenth[3]);

// logic work_en;

// always_ff @(posedge clk or negedeg rst_n) begin
//     if(!rst_n) begin
//         work_en <= 'b0;
//     end
//     else if(addr_mu_initial_en) begin
//         work_en <= 1'b1;
//     end
//     else if(addr_mu_finish) begin
//         work_en <= 'b0;
//     end
// end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        base_addr <= 'b0;
    end
    else if(addr_mu_initial_en) begin
        base_addr <= cfg_base_addr;
    end
end

always_comb begin
    loop_cnt_ns[0] = loop_cnt[0];
    loop_addr_ns[0] = loop_addr[0];

    if(addr_mu_initial_en) begin
        loop_cnt_ns[0] = 'b0;
        loop_addr_ns[0] = 'b0;
    end
    else if(addr_mu_valid & (& loop_target[3:1])) begin
        if(loop_target[0]) begin
            loop_cnt_ns[0] = 'b0;
            loop_addr_ns[0] = 'b0;
        end
        else begin
            loop_cnt_ns[0] = loop_cnt[0] + 1'b1;
            loop_addr_ns[0] = loop_addr[0] + cfg_gap[0];
        end
    end
end

always_comb begin
    loop_cnt_ns[1] = loop_cnt[1];
    loop_addr_ns[1] = loop_addr[1];

    if(addr_mu_initial_en) begin
        loop_cnt_ns[1] = 'b0;
        loop_addr_ns[1] = 'b0;
    end
    else if(addr_mu_valid & (& loop_target[3:2])) begin
        if(loop_target[1]) begin
            loop_cnt_ns[1] = 'b0;
            loop_addr_ns[1] = 'b0;
        end
        else begin
            loop_cnt_ns[1] = loop_cnt[1] + 1'b1;
            loop_addr_ns[1] = loop_addr[1] + cfg_gap[1];
        end
    end
end

always_comb begin
    loop_cnt_ns[2] = loop_cnt[2];
    loop_addr_ns[2] = loop_addr[2];

    if(addr_mu_initial_en) begin
        loop_cnt_ns[2] = 'b0;
        loop_addr_ns[2] = 'b0;
    end
    else if(addr_mu_valid & loop_target[3]) begin
        if(loop_target[2]) begin
            loop_cnt_ns[2] = 'b0;
            loop_addr_ns[2] = 'b0;
        end
        else begin
            loop_cnt_ns[2] = loop_cnt[2] + 1'b1;
            loop_addr_ns[2] = loop_addr[2] + cfg_gap[2];
        end
    end
end

always_comb begin
    loop_cnt_ns[3] = loop_cnt[3];
    loop_addr_ns[3] = loop_addr[3];

    if(addr_mu_initial_en) begin
        loop_cnt_ns[3] = 1;
        loop_addr_ns[3] = cfg_gap[3];
    end
    else if(addr_mu_valid) begin
        if(loop_target[3]) begin
            loop_cnt_ns[3] = 'b0;
            loop_addr_ns[3] = 'b0;
        end
        else begin
            loop_cnt_ns[3] = loop_cnt[3] + 1'b1;
            loop_addr_ns[3] = loop_addr[3] + cfg_gap[3];
        end
    end
end


always_comb begin
    addr_mu_addr_ns = addr_mu_addr;
    if(addr_mu_initial_en | addr_mu_valid) begin
        addr_mu_addr_ns = base_addr + loop_addr_ns[3] + loop_addr_ns[2] + loop_addr_ns[1] + loop_addr_ns[0];
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_mu_addr <= 'b0;
        loop_cnt <= 'b0;
        loop_addr <= 'b0;
    end
    else begin
        addr_mu_addr <= addr_mu_addr_ns;
        loop_cnt <= loop_cnt_ns;
        loop_addr <= loop_addr_ns;
    end
end



endmodule