
package example

import spinal.core._
import spinal.lib._
import spinal.lib.io._
import spinal.lib.bus.misc._
import spinal.lib.bus.amba3.apb._
import spinal.lib.com.uart._

class ExampleTop() extends Component 
{
    val io = new Bundle {

        val osc_clk_in    = in(Bool)

        val button        = in(Bool)

        val led_red       = out(Bool)
        val led_green     = out(Bool)
        val led_blue      = out(Bool)

        val uart          = master(Uart())
    }

    noIoPrefix()

    val clk_cpu =  Bool

    clk_cpu := io.osc_clk_in

    val clkCpuRawDomain = ClockDomain(
        clock       = clk_cpu,
        frequency   = FixedFrequency(50 MHz),
        config      = ClockDomainConfig(
            resetKind = BOOT
        )
    )

    //============================================================
    // Create clk_cpu reset
    //============================================================
    val clk_cpu_reset_ = Bool

    val clk_cpu_reset_gen = new ClockingArea(clkCpuRawDomain) {
        val reset_unbuffered_ = True

        val reset_cntr = Reg(UInt(5 bits)) init(0)
        when(reset_cntr =/= U(reset_cntr.range -> true)){
            reset_cntr := reset_cntr + 1
            reset_unbuffered_ := False
        }

        clk_cpu_reset_ := RegNext(reset_unbuffered_)
    }


    val clkCpuDomain = ClockDomain(
        clock       = clk_cpu,
        reset       = clk_cpu_reset_,
        frequency   = FixedFrequency(50 MHz),
        config      = ClockDomainConfig(
            resetKind = SYNC,
            resetActiveLevel = LOW
        )
    )

    val cpu = new ClockingArea(clkCpuDomain) {
        val u_cpu = new CpuTop()
        u_cpu.io.uart         <> io.uart
        u_cpu.io.led_red      <> io.led_red
        u_cpu.io.led_green    <> io.led_green
        u_cpu.io.led_blue     <> io.led_blue
    }

}


object ExampleTopVerilogSim {
    def main(args: Array[String]) {

        val config = SpinalConfig(anonymSignalUniqueness = true)

        config.generateVerilog({
            val toplevel = new ExampleTop()
            InOutWrapper(toplevel)
        })

    }
}

object ExampleTopVerilogSyn {
    def main(args: Array[String]) {

        val config = SpinalConfig(anonymSignalUniqueness = true)
        config.generateVerilog({
            val toplevel = new ExampleTop()
            InOutWrapper(toplevel)
            toplevel
        })
    }
}


