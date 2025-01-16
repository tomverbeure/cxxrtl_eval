
#include <iostream>
#include <fstream>
#include <iomanip>

#include <cxxrtl_lib.h>

#include "blink.cpp"

using namespace std;
using std::setw;

int main()
{
    cxxrtl_design::p_blink top;

    cxxrtl::debug_items all_debug_items;

    top.debug_info(&all_debug_items, nullptr, "");

    cout << "Restoring from checkpoint..." << endl;
    std::ifstream checkpoint("checkpoint.val");
    restore_state(all_debug_items, checkpoint);

    int prev_led = 1;

    top.p_clk = value<1>{1u};
    top.step();

    dump_all_items(all_debug_items);

    for(int steps=200;steps<1000;++steps){

        top.p_clk = value<1>{0u};
        top.step();

        top.p_clk = value<1>{1u};
        top.step();

        int cur_led = top.p_led.data[0];
        int counter = top.p_counter.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << " - counter: " << counter << endl;

        prev_led = cur_led;
    }
}

