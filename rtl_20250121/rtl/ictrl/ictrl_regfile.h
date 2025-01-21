/*
 * Reg Interface C-Header [AUTOGENERATE by SpinalHDL]
 * 
 */

#ifndef ICTRL_REGIF_H
#define ICTRL_REGIF_H

#define ICTRL_RD_CFG_EN        0x0000
#define ICTRL_RD_AFIFO_CONTROL 0x0004
#define ICTRL_RD_DFIFO_CONTROL 0x0008
#define ICTRL_RD_DFIFO_CONTROL_RD_CFG_DFIFO_THD_SHIFT      16
#define ICTRL_RD_DFIFO_CONTROL_RD_CFG_DFIFO_THD_MASK       0x00ff0000 //RW, 8 bit
#define ICTRL_RD_CTRL0         0x000c
#define ICTRL_RD_CTRL0_RD_CFG_OUTSTD_SHIFT                 0
#define ICTRL_RD_CTRL0_RD_CFG_OUTSTD_MASK                  0x0000000f //RW, 4 bit
#define ICTRL_RD_CTRL0_RD_CFG_OUTSTD_EN_SHIFT              4
#define ICTRL_RD_CTRL0_RD_CFG_OUTSTD_EN_MASK               0x00000010 //RW, 1 bit
#define ICTRL_RD_CTRL0_RD_CFG_CROSS4K_EN_SHIFT             5
#define ICTRL_RD_CTRL0_RD_CFG_CROSS4K_EN_MASK              0x00000020 //RW, 1 bit
#define ICTRL_RD_CTRL0_RD_CFG_ARVLD_HOLD_EN_SHIFT          6
#define ICTRL_RD_CTRL0_RD_CFG_ARVLD_HOLD_EN_MASK           0x00000040 //RW, 1 bit
#define ICTRL_RD_CTRL0_RD_CFG_RESI_MODE_SHIFT              7
#define ICTRL_RD_CTRL0_RD_CFG_RESI_MODE_MASK               0x00000080 //RW, 1 bit
#define ICTRL_RD_RESI_FMAP_A   0x0010
#define ICTRL_RD_RESI_FMAP_A_RD_CFG_RESI_FMAP_A_ADDR_SHIFT 0
#define ICTRL_RD_RESI_FMAP_A_RD_CFG_RESI_FMAP_A_ADDR_MASK  0x00000000 //RW, 32 bit
#define ICTRL_RD_RESI_FMAP_B   0x0014
#define ICTRL_RD_RESI_FMAP_B_RD_CFG_RESI_FMAP_B_ADDR_SHIFT 0
#define ICTRL_RD_RESI_FMAP_B_RD_CFG_RESI_FMAP_B_ADDR_MASK  0x00000000 //RW, 32 bit
#define ICTRL_RD_RESI_ADDR_GAP 0x0018
#define ICTRL_RD_RESI_ADDR_GAP_RD_CFG_RESI_ADDR_GAP_SHIFT  0
#define ICTRL_RD_RESI_ADDR_GAP_RD_CFG_RESI_ADDR_GAP_MASK   0x00000000 //RW, 32 bit
#define ICTRL_RD_RESI_LOOP_NUM 0x001c
#define ICTRL_RD_RESI_LOOP_NUM_RD_CFG_RESI_LOOP_NUM_SHIFT  0
#define ICTRL_RD_RESI_LOOP_NUM_RD_CFG_RESI_LOOP_NUM_MASK   0x00000000 //RW, 32 bit
#define ICTRL_RD_REQ           0x0020
#define ICTRL_RD_ADDR          0x0024
#define ICTRL_RD_ADDR_RD_ADDR_SHIFT                        0
#define ICTRL_RD_ADDR_RD_ADDR_MASK                         0x00000000 //RW, 32 bit
#define ICTRL_RD_NUM           0x0028
#define ICTRL_RD_NUM_RD_NUM_SHIFT                          0
#define ICTRL_RD_NUM_RD_NUM_MASK                           0x00000000 //RW, 32 bit
#define ICTRL_CFG_SEND         0x002c
#define ICTRL_GROUP_INFO       0x0030
#define ICTRL_GROUP_INFO_GROUP_INFO_SHIFT                  0
#define ICTRL_GROUP_INFO_GROUP_INFO_MASK                   0x00000000 //RW, 32 bit
#define ICTRL_CACHE_INFO       0x0034
#define ICTRL_CACHE_INFO_CACHE_INFO_SHIFT                  0
#define ICTRL_CACHE_INFO_CACHE_INFO_MASK                   0x00000000 //RW, 32 bit
#define ICTRL_RD_CNT           0x0038
#define ICTRL_NODES_STATUS     0x003c
#define ICTRL_INTR_INT_RAW     0x0040
#define ICTRL_INTR_INT_MASK    0x0044
#define ICTRL_INTR_INT_MASK_NODES_INTR_MASK_SHIFT          0
#define ICTRL_INTR_INT_MASK_NODES_INTR_MASK_MASK           0x00000001 //RW, 1 bit
#define ICTRL_INTR_INT_MASK_RD_DONE_INTR_MASK_SHIFT        1
#define ICTRL_INTR_INT_MASK_RD_DONE_INTR_MASK_MASK         0x00000002 //RW, 1 bit
#define ICTRL_INTR_INT_STATUS  0x0048

/**
  * @union       ictrl_rd_cfg_en_t
  * @address     0x0000
  * @brief       Enable DMA Read
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_en  :  1; //W1P, reset: 0x0, read config enable
        u32 reserved_0 : 31; //NA, Reserved
    } reg;
} ictrl_rd_cfg_en_t;

/**
  * @union       ictrl_rd_afifo_control_t
  * @address     0x0004
  * @brief       Init DMA Read Address FIFO
  */
typedef union {
    u32 val;
    struct {
        u32 rd_afifo_init :  1; //W1P, reset: 0x0, read addr fifo init
        u32 reserved_0    : 31; //NA, Reserved
    } reg;
} ictrl_rd_afifo_control_t;

/**
  * @union       ictrl_rd_dfifo_control_t
  * @address     0x0008
  * @brief       Control DMA Read Data FIFO
  */
typedef union {
    u32 val;
    struct {
        u32 rd_dfifo_init    :  1; //W1P, reset: 0x0, read data fifo init
        u32 reserved_0       : 15; //NA, Reserved
        u32 rd_cfg_dfifo_thd :  8; //RW, reset: 0x00, read data fifo threshold
        u32 reserved_1       :  8; //NA, Reserved
    } reg;
} ictrl_rd_dfifo_control_t;

/**
  * @union       ictrl_rd_ctrl0_t
  * @address     0x000c
  * @brief       Control DMA Read No.0
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_outstd        :  4; //RW, reset: 0x0, max outstanding num
        u32 rd_cfg_outstd_en     :  1; //RW, reset: 0x0, enable outstanding
        u32 rd_cfg_cross4k_en    :  1; //RW, reset: 0x0, enable cross 4k
        u32 rd_cfg_arvld_hold_en :  1; //RW, reset: 0x0, enable hold ar valid
        u32 rd_cfg_resi_mode     :  1; //RW, reset: 0x0, resi mode
        u32 reserved_0           : 24; //NA, Reserved
    } reg;
} ictrl_rd_ctrl0_t;

/**
  * @union       ictrl_rd_resi_fmap_a_t
  * @address     0x0010
  * @brief       Fmap A Address of DMA Read at Resi Mode
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_resi_fmap_a_addr : 32; //RW, reset: 0x00000000, resi mode A address
    } reg;
} ictrl_rd_resi_fmap_a_t;

/**
  * @union       ictrl_rd_resi_fmap_b_t
  * @address     0x0014
  * @brief       Fmap B Address of DMA Read at Resi Mode
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_resi_fmap_b_addr : 32; //RW, reset: 0x00000000, resi mode B address
    } reg;
} ictrl_rd_resi_fmap_b_t;

/**
  * @union       ictrl_rd_resi_addr_gap_t
  * @address     0x0018
  * @brief       Address Gap of DMA Read at Resi Mode
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_resi_addr_gap : 32; //RW, reset: 0x00000000, resi mode address gap
    } reg;
} ictrl_rd_resi_addr_gap_t;

/**
  * @union       ictrl_rd_resi_loop_num_t
  * @address     0x001c
  * @brief       Loop Number of DMA Read at Resi Mode
  */
typedef union {
    u32 val;
    struct {
        u32 rd_cfg_resi_loop_num : 32; //RW, reset: 0x00000000, resi mode loop number
    } reg;
} ictrl_rd_resi_loop_num_t;

/**
  * @union       ictrl_rd_req_t
  * @address     0x0020
  * @brief       Enable of DMA Read
  */
typedef union {
    u32 val;
    struct {
        u32 rd_req     :  1; //W1P, reset: 0x0, start read
        u32 reserved_0 : 31; //NA, Reserved
    } reg;
} ictrl_rd_req_t;

/**
  * @union       ictrl_rd_addr_t
  * @address     0x0024
  * @brief       Start Address of DMA Read
  */
typedef union {
    u32 val;
    struct {
        u32 rd_addr    : 32; //RW, reset: 0x00000000, read address
    } reg;
} ictrl_rd_addr_t;

/**
  * @union       ictrl_rd_num_t
  * @address     0x0028
  * @brief       Read How Many Data
  */
typedef union {
    u32 val;
    struct {
        u32 rd_num     : 32; //RW, reset: 0x00000000, read num
    } reg;
} ictrl_rd_num_t;

/**
  * @union       ictrl_cfg_send_t
  * @address     0x002c
  * @brief       Enable Config Send
  */
typedef union {
    u32 val;
    struct {
        u32 flit_send  :  1; //W1P, reset: 0x0, send config
        u32 reserved_0 : 31; //NA, Reserved
    } reg;
} ictrl_cfg_send_t;

/**
  * @union       ictrl_group_info_t
  * @address     0x0030
  * @brief       Group Info
  */
typedef union {
    u32 val;
    struct {
        u32 group_info : 32; //RW, reset: 0x00000000, group info
    } reg;
} ictrl_group_info_t;

/**
  * @union       ictrl_cache_info_t
  * @address     0x0034
  * @brief       Cache Start Addr/Work Enable
  */
typedef union {
    u32 val;
    struct {
        u32 cache_info : 32; //RW, reset: 0x00000000, cache info
    } reg;
} ictrl_cache_info_t;

/**
  * @union       ictrl_rd_cnt_t
  * @address     0x0038
  * @brief       DMA read in Count
  */
typedef union {
    u32 val;
    struct {
        u32 debug_dma_rd_in_cnt : 16; //RO, reset: 0x0000, DMA read in Count
        u32 reserved_0          : 16; //NA, Reserved
    } reg;
} ictrl_rd_cnt_t;

/**
  * @union       ictrl_nodes_status_t
  * @address     0x003c
  * @brief       Status of 12 Nodes
  */
typedef union {
    u32 val;
    struct {
        u32 nodes_status : 12; //RO, reset: 0x000, Status of 12 Nodes
        u32 reserved_0   : 20; //NA, Reserved
    } reg;
} ictrl_nodes_status_t;

/**
  * @union       ictrl_intr_int_raw_t
  * @address     0x0040
  * @brief       Interrupt Raw status Register\n set when event \n clear when write 1
  */
typedef union {
    u32 val;
    struct {
        u32 nodes_intr_raw   :  1; //W1C, reset: 0x0, raw, default 0
        u32 rd_done_intr_raw :  1; //W1C, reset: 0x0, raw, default 0
        u32 reserved_0       : 30; //NA, Reserved
    } reg;
} ictrl_intr_int_raw_t;

/**
  * @union       ictrl_intr_int_mask_t
  * @address     0x0044
  * @brief       Interrupt Mask   Register\n1: int off\n0: int open\n default 1, int off
  */
typedef union {
    u32 val;
    struct {
        u32 nodes_intr_mask   :  1; //RW, reset: 0x1, mask, default 1, int off
        u32 rd_done_intr_mask :  1; //RW, reset: 0x1, mask, default 1, int off
        u32 reserved_0        : 30; //NA, Reserved
    } reg;
} ictrl_intr_int_mask_t;

/**
  * @union       ictrl_intr_int_status_t
  * @address     0x0048
  * @brief       Interrupt status Register\n  status = raw && (!mask)
  */
typedef union {
    u32 val;
    struct {
        u32 nodes_intr_status   :  1; //RO, reset: 0x0, stauts default 0
        u32 rd_done_intr_status :  1; //RO, reset: 0x0, stauts default 0
        u32 reserved_0          : 30; //NA, Reserved
    } reg;
} ictrl_intr_int_status_t;

#endif /* ICTRL_REGIF_H */
