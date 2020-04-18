package cc

// All code copied from vexriscv.demo.Murax

import java.nio.{ByteBuffer, ByteOrder}
import java.nio.file.{Files, Paths}

import spinal.core._
import spinal.lib.bus.amba3.apb.{Apb3, Apb3Config, Apb3SlaveFactory}
import spinal.lib.bus.misc.SizeMapping
import spinal.lib._
import spinal.lib.bus.simple._
import vexriscv.plugin.{DBusSimpleBus, IBusSimpleBus}

class CCMasterArbiter(pipelinedMemoryBusConfig : PipelinedMemoryBusConfig) extends Component{
  val io = new Bundle{
    val iBus = slave(IBusSimpleBus(null))
    val dBus = slave(DBusSimpleBus())
    val masterBus = master(PipelinedMemoryBus(pipelinedMemoryBusConfig))
  }

  io.masterBus.cmd.valid   := io.iBus.cmd.valid || io.dBus.cmd.valid
  io.masterBus.cmd.write      := io.dBus.cmd.valid && io.dBus.cmd.wr
  io.masterBus.cmd.address := io.dBus.cmd.valid ? io.dBus.cmd.address | io.iBus.cmd.pc
  io.masterBus.cmd.data    := io.dBus.cmd.data
  io.masterBus.cmd.mask    := io.dBus.cmd.size.mux(
    0 -> B"0001",
    1 -> B"0011",
    default -> B"1111"
  ) |<< io.dBus.cmd.address(1 downto 0)
  io.iBus.cmd.ready := io.masterBus.cmd.ready && !io.dBus.cmd.valid
  io.dBus.cmd.ready := io.masterBus.cmd.ready


  val rspPending = RegInit(False) clearWhen(io.masterBus.rsp.valid)
  val rspTarget = RegInit(False)
  when(io.masterBus.cmd.fire && !io.masterBus.cmd.write){
    rspTarget  := io.dBus.cmd.valid
    rspPending := True
  }

  when(rspPending && !io.masterBus.rsp.valid){
    io.iBus.cmd.ready := False
    io.dBus.cmd.ready := False
    io.masterBus.cmd.valid := False
  }

  io.iBus.rsp.valid := io.masterBus.rsp.valid && !rspTarget
  io.iBus.rsp.inst  := io.masterBus.rsp.data
  io.iBus.rsp.error := False

  io.dBus.rsp.ready := io.masterBus.rsp.valid && rspTarget
  io.dBus.rsp.data  := io.masterBus.rsp.data
  io.dBus.rsp.error := False
}


case class CCPipelinedMemoryBusRam(onChipRamSize : BigInt, onChipRamBinFile : String, pipelinedMemoryBusConfig : PipelinedMemoryBusConfig) extends Component{
  val io = new Bundle{
    val bus = slave(PipelinedMemoryBus(pipelinedMemoryBusConfig))
  }

  val ram = Mem(Bits(32 bits), onChipRamSize / 4)
  io.bus.rsp.valid := RegNext(io.bus.cmd.fire && !io.bus.cmd.write) init(False)
  io.bus.rsp.data := ram.readWriteSync(
    address = (io.bus.cmd.address >> 2).resized,
    data  = io.bus.cmd.data,
    enable  = io.bus.cmd.valid,
    write  = io.bus.cmd.write,
    mask  = io.bus.cmd.mask
  )
  io.bus.cmd.ready := True

  if(onChipRamBinFile != null){

    val byteArray = Files.readAllBytes(Paths.get(onChipRamBinFile))

    val initContent  = for(i <- 0 until onChipRamSize.toInt/4) yield {
          BigInt( (byteArray(4*i).toLong & 0xff) + ((byteArray(4*i+1).toLong & 0xff)<<8) + ((byteArray(4*i+2).toLong & 0xff)<<16) + ((byteArray(4*i+3).toLong & 0xff)<<24) )
        }
    ram.initBigInt(initContent)
  }
}



case class Apb3Rom(onChipRamBinFile : String) extends Component{
  val byteArray = Files.readAllBytes(Paths.get(onChipRamBinFile))
  val wordCount = (byteArray.length+3)/4
  val buffer = ByteBuffer.wrap(Files.readAllBytes(Paths.get(onChipRamBinFile))).order(ByteOrder.LITTLE_ENDIAN);
  val wordArray = (0 until wordCount).map(i => {
    val v = buffer.getInt
    if(v < 0)  BigInt(v.toLong & 0xFFFFFFFFl) else  BigInt(v)
  })

  val io = new Bundle{
    val apb = slave(Apb3(log2Up(wordCount*4),32))
  }

  val rom = Mem(Bits(32 bits), wordCount) initBigInt(wordArray)
//  io.apb.PRDATA := rom.readSync(io.apb.PADDR >> 2)
  io.apb.PRDATA := rom.readAsync(RegNext(io.apb.PADDR >> 2))
  io.apb.PREADY := True
}



class CCPipelinedMemoryBusDecoder(master : PipelinedMemoryBus, val specification : Seq[(PipelinedMemoryBus,SizeMapping)], pipelineMaster : Boolean) extends Area{
  val masterPipelined = PipelinedMemoryBus(master.config)
  if(!pipelineMaster) {
    masterPipelined.cmd << master.cmd
    masterPipelined.rsp >> master.rsp
  } else {
    masterPipelined.cmd <-< master.cmd
    masterPipelined.rsp >> master.rsp
  }

  val slaveBuses = specification.map(_._1)
  val memorySpaces = specification.map(_._2)

  val hits = for((slaveBus, memorySpace) <- specification) yield {
    val hit = memorySpace.hit(masterPipelined.cmd.address)
    slaveBus.cmd.valid   := masterPipelined.cmd.valid && hit
    slaveBus.cmd.payload := masterPipelined.cmd.payload.resized
    hit
  }
  val noHit = !hits.orR
  masterPipelined.cmd.ready := (hits,slaveBuses).zipped.map(_ && _.cmd.ready).orR || noHit

  val rspPending  = RegInit(False) clearWhen(masterPipelined.rsp.valid) setWhen(masterPipelined.cmd.fire && !masterPipelined.cmd.write)
  val rspNoHit    = RegNext(False) init(False) setWhen(noHit)
  val rspSourceId = RegNextWhen(OHToUInt(hits), masterPipelined.cmd.fire)
  masterPipelined.rsp.valid   := slaveBuses.map(_.rsp.valid).orR || (rspPending && rspNoHit)
  masterPipelined.rsp.payload := slaveBuses.map(_.rsp.payload).read(rspSourceId)

  when(rspPending && !masterPipelined.rsp.valid) { //Only one pending read request is allowed
    masterPipelined.cmd.ready := False
    slaveBuses.foreach(_.cmd.valid := False)
  }
}

