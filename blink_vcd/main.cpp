
#include <iostream>
#include <fstream>

#include <cxxrtl/cxxrtl_vcd.h>

#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    // debug_items maps the hierarchical names of signals and memories in the design
    // to a cxxrtl_object (a value, a wire, or a memory)
    cxxrtl::debug_items all_debug_items;

    // Load the debug items of the top down the whole design hierarchy
    top.debug_info(&all_debug_items, nullptr, "");

    // vcd_writer is the CXXRTL object that's responsible of creating a string with
    // the VCD file contents.
    cxxrtl::vcd_writer vcd;
    vcd.timescale(1, "us");

    // Here we tell the vcd writer to dump all the signals of the design, except for the
    // memories, to the VCD file.
    //
    // It's not necessary to load all debug objects to the VCD. There is, for example,
    // a  vcd.add(<debug items>, <filter>)) method which allows creating your custom filter to decide
    // what to add and what not. 
    vcd.add_without_memories(all_debug_items);

    std::ofstream waves("waves.vcd");

    bool prev_led = 0;

    top.step();

    // We need to manually tell the VCD writer when sample and write out the traced items.
    // This is only a slight inconvenience and allows for complete flexibilty.
    // E.g. you could only start waveform tracing when an internal signal has reached some specific
    // value etc.
    vcd.sample(0);

    for(int steps=0;steps<1000;++steps){

        top.p_clk.set<bool>(false);
        top.step();
        vcd.sample(steps*2 + 0);

        top.p_clk.set<bool>(true);
        top.step();
        vcd.sample(steps*2 + 1);

        bool cur_led = top.p_led.get<bool>();

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << endl;

        prev_led = cur_led;

        waves << vcd.buffer;
        vcd.buffer.clear();
    }
}

