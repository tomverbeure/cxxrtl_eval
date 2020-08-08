
#include <iostream>
#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    bool prev_led = 0;

    top.step();
    for(int cycle=0;cycle<1000;++cycle){

        top.p_clk.set<bool>(0);
        top.step();
        top.p_clk.set<bool>(1);
        top.step();

        bool cur_led        = top.p_led.get<bool>();
        uint32_t counter    = top.p_counter.get<uint32_t>();

        if (cur_led != prev_led){
            cout << "cycle " << cycle << " - led: " << cur_led << ", counter: " << counter << endl;
        }
        prev_led = cur_led;
    }
}

