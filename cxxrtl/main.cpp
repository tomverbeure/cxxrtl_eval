
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

    // <executable> <debug level> <vcd filename> 
    // debug level:
    // 0 -> No dumping, no save/restore
    // 1 -> dump everything
    // 2 -> dump everything except memories
    // 3 -> dump custom (only wires)
    // 4 -> save to checkpoint
    // 5 -> restore from checkpoint

    if (argc >= 2){
        dump_level = atoi(argv[1]);
    }

    if (argc >= 3){
        filename = argv[2];
    } 

    cxxrtl_design::p_ExampleTop top;
    cxxrtl::debug_items all_debug_items;
    top.debug_info(all_debug_items);
    cxxrtl::vcd_writer vcd;
    std::ofstream waves;

    if (dump_level >=1 && dump_level <= 3){
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

    if (dump_level == 5){
        cout << "Restoring from checkpoint..." << endl;
        std::ifstream checkpoint("checkpoint.val");
        restore_state(all_debug_items, checkpoint);
        cout << "Restore done..." << endl;
        dump_all_items(all_debug_items);
    }

    top.p_osc__clk__in.set<bool>(true);
    top.step();

    if (dump_level >=1 && dump_level <= 3)
        vcd.sample(0);

#ifdef SPY_UART_TX
    cxxrtl::debug_item psel    = all_debug_items.at("cpu_u_cpu u_uart io_apb_PSEL");
    cxxrtl::debug_item penable = all_debug_items.at("cpu_u_cpu u_uart io_apb_PENABLE");
    cxxrtl::debug_item pwrite  = all_debug_items.at("cpu_u_cpu u_uart io_apb_PWRITE");
    cxxrtl::debug_item pwdata  = all_debug_items.at("cpu_u_cpu u_uart io_apb_PWDATA");
    cxxrtl::debug_item paddr   = all_debug_items.at("cpu_u_cpu u_uart io_apb_PADDR");
#endif

    int led_red_cntr = 0;

    for(int i=0;i<1000000;++i){
        top.p_osc__clk__in.set<bool>(false);
        top.step();

        if (dump_level >=1 && dump_level <= 3)
            vcd.sample(i*2 + 0);

        top.p_osc__clk__in.set<bool>(true);
        top.step();

#ifdef SPY_UART_TX
        if (debug_item_get_value32(psel)    &&
            debug_item_get_value32(penable) &&
            debug_item_get_value32(pwrite)  &&
            debug_item_get_value32(paddr) == 0
        ){
            // APB write to UART RXTX register
            cout << "UART TX: " << (char)debug_item_get_value32(pwdata) << endl;
        }
#endif


        if (dump_level == 4 && i==10000){
            cout << "Saving checkpoint..." << endl;
            std::ofstream checkpoint("checkpoint.val");
            save_state(all_debug_items, checkpoint);
            exit(0);
        }

        if (dump_level >= 1 && dump_level <= 3)
            vcd.sample(i*2 + 1);

        bool cur_led_red    = top.p_led__red.get<bool>();
        bool cur_led_green  = top.p_led__green.get<bool>();
        bool cur_led_blue   = top.p_led__blue.get<bool>();

        if (cur_led_red != prev_led_red){
            cout << "led_red: " << cur_led_red << " " << led_red_cntr << endl;
            if (cur_led_red)
                    ++led_red_cntr;
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

        if (dump_level >= 1 && dump_level <= 3){
            waves << vcd.buffer;
            vcd.buffer.clear();
        }
    }
}

