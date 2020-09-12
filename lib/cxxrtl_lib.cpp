
#include <backends/cxxrtl/cxxrtl.h>

#include <iostream>
#include <fstream>
#include <iomanip>

using namespace std;
using std::setw;

void save_state(cxxrtl::debug_items &items, std::ofstream &save_file)
{
    save_file << items.table.size() << endl;
    for(auto &it : items.table){
        for(auto &part: it.second){
            save_file << it.first << endl; 
            save_file << part.curr[0] << endl;
        }
    }
}

void restore_state(cxxrtl::debug_items &items, std::ifstream &restore_file)
{
    int size;

    restore_file >> size;

    for(int i=0;i<size;++i){
        std::string name;
        uint32_t value;

        restore_file >> name;
        restore_file >> value;

        cout << name << ":" << value << endl;

        vector<cxxrtl::debug_item> &item_parts = items.table[name];
        assert(item_parts.size() == 1);
        item_parts[0].curr[0] = value;
    }
}

