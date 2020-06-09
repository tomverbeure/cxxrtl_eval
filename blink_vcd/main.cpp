
#include <iostream>
#include <fstream>

#include <backends/cxxrtl/cxxrtl_vcd.h>

#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    cxxrtl::debug_items debug;
    top.debug_info(debug);

    cxxrtl::vcd_writer vcd;
    vcd.timescale(1, "us");
    vcd.add(debug);

    std::ofstream waves("waves.vcd");

    int prev_led = 0;

    top.step();
    vcd.sample(0);

    for(int steps=0;steps<1000;++steps){

        top.p_clk = value<1>{0u};
        top.step();
        vcd.sample(steps*2 + 0);
        top.p_clk = value<1>{1u};
        top.step();
        vcd.sample(steps*2 + 1);

        int cur_led= top.p_led.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << steps << " - led: " << cur_led << endl;

        prev_led = cur_led;

    }

    waves << vcd.buffer;

}

