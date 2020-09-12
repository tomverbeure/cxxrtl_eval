
#include <iostream>
#include <fstream>
#include <iomanip>

#include <backends/cxxrtl/cxxrtl_vcd.h>

#include <cxxrtl_lib.h>

#include EXAMPLE_TOP

using namespace std;

int main(int argc, char **argv)
{
    char *filename;
    int dump_level = 0;

    if (argc >= 3){
        filename = argv[1];
        dump_level = atoi(argv[2]);
    } 

    cxxrtl_design::p_ExampleTop top;
    cxxrtl::debug_items all_debug_items;
    top.debug_info(all_debug_items);
    cxxrtl::vcd_writer vcd;
    std::ofstream waves;

    if (dump_level){
        vcd.timescale(1, "us");
        if (dump_level == 1)
            vcd.add(all_debug_items);
        else if (dump_level == 2)
            vcd.add_without_memories(all_debug_items);
        else if (dump_level == 3)
		    vcd.template add(all_debug_items, [](const std::string &, const debug_item &item) {
			    return item.type == debug_item::WIRE;
		    });
        waves.open(filename);
    }

    bool prev_led_red, prev_led_green, prev_led_blue;

    top.step();

    if (dump_level)
        vcd.sample(0);

    for(int i=0;i<1000000;++i){
        top.p_osc__clk__in.set<bool>(false);
        top.step();

        if (dump_level)
            vcd.sample(i*2 + 0);

        top.p_osc__clk__in.set<bool>(true);
        top.step();

#if 0
        if (i==10000){
            cout << "Saving checkpoint..." << endl;
            std::ofstream checkpoint("checkpoint.val");
            save_state(all_debug_items, checkpoint);
        }
#endif

        if (dump_level)
            vcd.sample(i*2 + 1);

        bool cur_led_red    = top.p_led__red.get<bool>();
        bool cur_led_green  = top.p_led__green.get<bool>();
        bool cur_led_blue   = top.p_led__blue.get<bool>();

        if (cur_led_red != prev_led_red){
            cout << "led_red: " << cur_led_red << endl;
        }

        if (cur_led_green != prev_led_green){
            cout << "led_green: " << cur_led_green << endl;
        }

        if (cur_led_blue != prev_led_blue){
            cout << "led_blue: " << cur_led_blue << endl;
        }

        prev_led_red    = cur_led_red;
        prev_led_green  = cur_led_green;
        prev_led_blue   = cur_led_blue;

        if (dump_level){
            waves << vcd.buffer;
            vcd.buffer.clear();
        }
    }
}

