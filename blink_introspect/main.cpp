
#include <iostream>
#include <fstream>
#include <iomanip>

#include "blink.cpp"

using namespace std;
using std::setw;

int main()
{
    cxxrtl_design::p_blink top;

    cxxrtl::debug_items all_debug_items;

    top.debug_info(all_debug_items);

    // Print all the introspectable information of all debug items
    for(auto &it : all_debug_items)
        cout << setw(10) << it.first << " : type = " << it.second.type << " : width = " << setw(4) << it.second.width << " : depth = " << setw(6) << it.second.depth << endl;

    int prev_led = 0;

    top.step();

    for(int steps=0;steps<1000;++steps){

        top.p_clk = value<1>{0u};
        top.step();

        top.p_clk = value<1>{1u};
        top.step();

        int cur_led = top.p_led.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << endl;

        prev_led = cur_led;
    }
}

