#ifndef CXXRTL_LIB_H
#define CXXRTL_LIB_H

#include <backends/cxxrtl/cxxrtl.h>

void save_state(cxxrtl::debug_items &items, std::ofstream &save_file);
void restore_state(cxxrtl::debug_items &items, std::ifstream &restore_file);


#endif
