
#include <iostream>
#include <fstream>
#include <iomanip>

#include <cxxrtl_lib.h>

#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    cxxrtl::debug_items all_debug_items;

    top.debug_info(&all_debug_items, nullptr, "");

    // Print all the introspectable information of all debug items
    for(auto &it : all_debug_items.table)
        for(auto &part: it.second)
            cout << setw(20) << it.first << " : type = " << part.type << " : width = " << setw(4) << part.width << " : depth = " << setw(6) << part.depth 
                 << setw(4)  << " : lsb_at = " << part.lsb_at << " : zero_at = " << part.zero_at << endl;

    int prev_led = 0;

    top.step();

    for(int steps=0;steps<1000;++steps){

        top.p_clk = value<1>{0u};
        top.step();

        top.p_clk = value<1>{1u};
        top.step();

        int cur_led = top.p_led.data[0];
        int counter = top.p_counter.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << " - counter: " << counter << endl;

        if (counter == 200){
            dump_all_items(all_debug_items);

            std::ofstream checkpoint("checkpoint.val");
            save_state(all_debug_items, checkpoint);

            exit(0);
        }

        prev_led = cur_led;
    }
}

