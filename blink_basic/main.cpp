
#include <iostream>
#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    bool prev_led = 0;

    top.step();
    for(int cycle=0;cycle<1000;++cycle){

        top.p_clk = value<1>{0u};
        top.step();
        top.p_clk = value<1>{1u};
        top.step();

        bool cur_led        = top.p_led.get<bool>();
        uint32_t counter    = top.p_counter.get<uint32_t>();

        if (cur_led != prev_led){
            cout << "cycle " << cycle << " - led: " << cur_led << ", counter: " << counter << endl;
        }

        if (counter == 130){
            top.p_counter.set<uint16_t>(0);
        }

        prev_led = cur_led;
    }
}

