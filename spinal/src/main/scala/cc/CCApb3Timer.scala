package cc

// All code copied from vexriscv.demo.Murax

import spinal.core._
import spinal.lib.bus.amba3.apb.{Apb3, Apb3Config, Apb3SlaveFactory}
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.misc.{ InterruptCtrl, Prescaler, Timer}
import spinal.lib._
import spinal.lib.bus.simple._

class CCApb3Timer extends Component{
    val io = new Bundle {
        val apb = slave(Apb3(
            addressWidth = 8,
            dataWidth = 32
        ))
        val interrupt = out Bool
    }

    val prescaler = Prescaler(8)
    val timerA,timerB = Timer(16)

    val busCtrl = Apb3SlaveFactory(io.apb)
    val prescalerBridge = prescaler.driveFrom(busCtrl,0x00)

    val timerABridge = timerA.driveFrom(busCtrl,0x40)(
        ticks  = List(True, prescaler.io.overflow),
        clears = List(timerA.io.full)
    )

    val timerBBridge = timerB.driveFrom(busCtrl,0x50)(
        ticks  = List(True, prescaler.io.overflow),
        clears = List(timerB.io.full)
    )

    val interruptCtrl = InterruptCtrl(2)
    val interruptCtrlBridge = interruptCtrl.driveFrom(busCtrl,0x10)
    interruptCtrl.io.inputs(0) := timerA.io.full
    interruptCtrl.io.inputs(1) := timerB.io.full
    io.interrupt := interruptCtrl.io.pendings.orR
}


object CCApb3TimerGen extends App{
    SpinalVhdl(new CCApb3Timer())
}
