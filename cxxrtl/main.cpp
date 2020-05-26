
#include <iostream>

#include EXAMPLE_TOP

using namespace std;

int main()
{
    cxxrtl_design::p_ExampleTop top;

    int prev_led_red, prev_led_green, prev_led_blue;

    top.step();
    for(int i=0;i<1000000;++i){
        top.p_osc__clk__in = value<1>{0u};
        top.step();
        top.p_osc__clk__in = value<1>{1u};
        top.step();

        int cur_led_red = top.p_led__red.curr.data[0];

        if (cur_led_red != prev_led_red){
            cout << "led_red: " << cur_led_red << endl;
        }

        int cur_led_green = top.p_led__green.curr.data[0];

        if (cur_led_green != prev_led_green){
            cout << "led_green: " << cur_led_green << endl;
        }

        int cur_led_blue = top.p_led__blue.curr.data[0];

        if (cur_led_blue != prev_led_blue){
            cout << "led_blue: " << cur_led_blue << endl;
        }


        prev_led_red = cur_led_red;
        prev_led_green = cur_led_green;
        prev_led_blue = cur_led_blue;
    }
}

