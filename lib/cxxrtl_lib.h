#ifndef CXXRTL_LIB_H
#define CXXRTL_LIB_H

#include <cxxrtl/cxxrtl.h>

void save_state(cxxrtl::debug_items &items, std::ofstream &save_file, uint32_t types = (CXXRTL_WIRE | CXXRTL_MEMORY));
void restore_state(cxxrtl::debug_items &items, std::ifstream &restore_file, uint32_t types = (CXXRTL_WIRE | CXXRTL_MEMORY));
void dump_all_items(cxxrtl::debug_items &items);
uint32_t debug_item_get_value32(cxxrtl::debug_item &item);

#endif
