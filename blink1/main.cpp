
#include <iostream>
#include "blink.cpp"

using namespace std;

int main()
{
    cxxrtl_design::p_blink top;

    int prev_led = 0;

    top.step();
    for(int i=0;i<1000;++i){

        top.p_clk = value<1>{0u};
        top.step();
        top.p_clk = value<1>{1u};
        top.step();

        int cur_led= top.p_led.curr.data[0];

        if (cur_led != prev_led)
            cout << "cycle " << i << " - led: " << cur_led << endl;

        prev_led = cur_led;
    }
}

