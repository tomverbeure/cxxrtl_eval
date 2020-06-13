
#include <iostream>
#include <fstream>

#include <backends/cxxrtl/cxxrtl_vcd.h>

#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    // debug_items maps a string with the hierarchical paths inside the design to 
    // a cxxrtl_object (a value, a wire, or a memory)
    cxxrtl::debug_items all_debug_items;

    // Load the debug items of the top down the whole design hierarchy
    top.debug_info(all_debug_items);

    cxxrtl::vcd_writer vcd;
    vcd.timescale(1, "us");

    // All debug items are added to the vcd file.
    // We don't necessarily have to load all debug objects to the VCD. There is, for example,
    // an vcd.add(<debug items>, <filter>)) method which allows creating your custom filter to decide
    // what to add and what not. 
    vcd.add_without_memories(all_debug_items);

    std::ofstream waves("waves.vcd");

    int prev_led = 0;

    top.step();

    // We need to manually issue the VCD writer to sample all the traced items and write them out.
    // This is only a slight inconvenience and allows for complete flexibilty.
    // E.g. you could only start waveform tracing when an internal signal has reached some specific
    // value etc.
    vcd.sample(0);

    for(int steps=0;steps<1000;++steps){

        top.p_clk = value<1>{0u};
        top.step();
        vcd.sample(steps*2 + 0);

        top.p_clk = value<1>{1u};
        top.step();
        vcd.sample(steps*2 + 1);

        int cur_led = top.p_led.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << endl;

        prev_led = cur_led;

        waves << vcd.buffer;
        vcd.buffer.clear();
    }
}

