
#include <iostream>
#include <fstream>
#include <iomanip>

#include "blink.cpp"

using namespace std;
using std::setw;


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
                 << " ; zero_at = " << setw(3) << part.zero_at << endl;
    cout << endl;
}

void dump_item_value(cxxrtl::debug_items &items, std::string path)
{
    cxxrtl::debug_item item = items.at(path)[0];

    // Number of chunks per value
    const size_t nr_chunks = (item.width + (sizeof(chunk_t) * 8 - 1)) / (sizeof(chunk_t) * 8);

    cout << "\"" << path << "\":"  << endl;

    for (size_t index = 0; index < item.depth; index++) {
        if (item.depth > 1)
            cout << "location[" << index << "] : "; 

        for(size_t chunk_nr = 0; chunk_nr < nr_chunks; ++chunk_nr){
            cout << item.curr[nr_chunks * index + chunk_nr];
            cout << (chunk_nr == nr_chunks-1 ? "\n" : ",  ");
        }
    }
}

int main()
{
    cxxrtl_design::p_top top;

    cxxrtl::debug_items all_debug_items;

    top.debug_info(&all_debug_items, nullptr, "");

    dump_all_items(all_debug_items);

    bool prev_led = false;

    top.step();

    for(int steps=0;steps<1000;++steps){

        top.p_clk.set<bool>(false);
        top.step();

        top.p_clk.set<bool>(true);
        top.step();

        bool cur_led = top.p_led.get<bool>();

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << endl;

        if (steps == 200){
            dump_item_value(all_debug_items, "u_blink counter");
            dump_item_value(all_debug_items, "mem");
        }


        prev_led = cur_led;
    }
}

