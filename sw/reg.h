#ifndef REG_H
#define REG_H

#define REG_WR(reg_name, wr_data)                   (*((volatile uint32_t *)(0x80000000 | reg_name##_ADDR)) = (wr_data))
#define REG_RD(reg_name)                            (*((volatile uint32_t *)(0x80000000 | reg_name##_ADDR)))

#define FIELD_MASK(reg_name, field_name)            ( ((1<<(reg_name##_##field_name##_FIELD_LENGTH))-1) << (reg_name##_##field_name##_FIELD_START))

#define REG_WR_FIELD(reg_name, field_name, wr_data) (*((volatile uint32_t *)(0x80000000 | reg_name##_ADDR)) = \
                                                                ((REG_RD(reg_name) \
                                                                & ~FIELD_MASK(reg_name, field_name)) \
                                                                | (((wr_data)<<(reg_name##_##field_name##_FIELD_START)) & FIELD_MASK(reg_name, field_name))))

#define REG_RD_FIELD(reg_name, field_name)          ((REG_RD(reg_name) & FIELD_MASK(reg_name, field_name)) >> (reg_name##_##field_name##_FIELD_START))


#define MEM_WR(mem_name, wr_addr, wr_data)          (*( (volatile uint32_t *)(0x80000000 | mem_name##_ADDR) + (wr_addr)) = (wr_data))
#define MEM_RD(mem_name, rd_addr)                   (*( (volatile uint32_t *)(0x80000000 | mem_name##_ADDR) + (rd_addr)))

#define GET_FIELD(var, reg_name, field_name)        (((var) >> (reg_name##_##field_name##_##FIELD_START)) & ((1<<(reg_name##_##field_name##_##FIELD_LENGTH))-1))

#endif
