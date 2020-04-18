
package example

import spinal.core._
import spinal.lib._
import spinal.lib.io._
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.com.uart._
import spinal.lib.com.i2c._

import scala.collection.mutable.ArrayBuffer
import cc._

case class CpuTop() extends Component {

    val io = new Bundle {
        val led_red     = out(Bool)
        val led_green   = out(Bool)
        val led_blue    = out(Bool)

        val uart        = master(Uart())
    }

    val cpuConfig = CpuComplexConfig.default.copy(onChipRamBinFile = "../sw/progmem_full.bin")
    //val cpuConfig = CpuComplexConfig.default

    val u_cpu = CpuComplex(cpuConfig)
    u_cpu.io.externalInterrupt := False

    val apbMapping = ArrayBuffer[(Apb3, SizeMapping)]()

    //============================================================
    // Timer
    //============================================================

    val u_timer = new CCApb3Timer()
    u_timer.io.interrupt        <> u_cpu.io.timerInterrupt
    apbMapping += u_timer.io.apb -> (0x00000, 4 kB)

    //============================================================
    // GPIO control, bits:
    // 0 - Green LED
    // 1 - Blue LED
    // 2 - Red LED  (write only: hardware limitation)
    // 3 - Pano button
    //============================================================

    val u_led_ctrl = Apb3Gpio(3, withReadSync = true)
    u_led_ctrl.io.gpio.write(0)             <> io.led_red
    u_led_ctrl.io.gpio.write(1)             <> io.led_green
    u_led_ctrl.io.gpio.write(2)             <> io.led_blue
    u_led_ctrl.io.gpio.read(0)              := io.led_red
    u_led_ctrl.io.gpio.read(1)              := io.led_green
    u_led_ctrl.io.gpio.read(2)              := io.led_blue

    apbMapping += u_led_ctrl.io.apb -> (0x10000, 4 kB)

    //============================================================
    // Uart
    //============================================================
    
    val uartConfig = UartCtrlMemoryMappedConfig(
          uartCtrlConfig  = UartCtrlGenerics(),
          initConfig      = UartCtrlInitConfig(
              baudrate    = 115200
          ),
          txFifoDepth     = 255
      )

    val u_uart = Apb3UartCtrl(config = uartConfig)
    u_uart.io.uart      <> io.uart

    apbMapping += u_uart.io.apb -> (0x20000, 4 kB)
      
    //============================================================
    // External APBs
    //============================================================

    //============================================================
    // Local APB decoder
    //============================================================
    val apbDecoder = Apb3Decoder(
      master = u_cpu.io.apb,
      slaves = apbMapping
    )

}

