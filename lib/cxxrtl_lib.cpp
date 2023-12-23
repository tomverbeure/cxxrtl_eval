#include <cxxrtl/cxxrtl.h>

#include <iostream>
#include <fstream>
#include <iomanip>

using namespace std;
using std::setw;

void save_state(cxxrtl::debug_items &items, std::ofstream &save_file, uint32_t types)
{
    save_file << items.table.size() << endl;
    for(auto &it : items.table){
        save_file << it.first << endl; 
        for(auto &part: it.second){
            if (part.type & types){
                uint32_t *mem_data = part.curr;
                for(int a=0;a<part.depth;++a){
                    for(int n=0;n<part.width;n+=32){
                        save_file << *mem_data << endl;
                        ++mem_data;
                    }
                }
            }
        }
    }
}

void restore_state(cxxrtl::debug_items &items, std::ifstream &restore_file, uint32_t types)
{
    int size;
    restore_file >> size;

    for(int i=0;i<size;++i){
        std::string name;
        uint32_t value;

        std::getline(restore_file,name);
        //cout << name << endl;

        vector<cxxrtl::debug_item> &item_parts = items.table[name];
        for(auto &part: item_parts){
            if (part.type & types){
                uint32_t *mem_data = part.curr;
                for(int a=0;a<part.depth;++a){
                    for(int n=0;n<part.width;n+=32){
                        restore_file >> value;
                        *mem_data = value;
                        ++mem_data;

                        //cout << value << endl;
                    }
                }
            }
        }
    }
}

void dump_all_items(cxxrtl::debug_items &items)
{
    cout << "All items:" << endl;
    for(auto &it : items.table)
        for(auto &part: it.second)
            cout << setw(24) << it.first 
                 << " : type = " << part.type 
                 << " ; width = " << setw(4) << part.width 
                 << " ; depth = " << setw(6) << part.depth 
                 << " ; lsb_at = " << setw(3) << part.lsb_at 
                 << " ; zero_at = " << setw(3) << part.zero_at 
                 << " ; value = " << *it.second.begin()->curr 
                 << endl;
    cout << endl;
}

uint32_t debug_item_get_value32(cxxrtl::debug_item &item)
{
    //return *item.begin()->curr;
    return *item.curr;
}


