
all: syn

.PHONY: submodule
submodule:
	cd ../ && git submodule update --init

.PHONY: sw
sw:
	cd ../sw && make


syn: submodule sw
	sbt "runMain example.ExampleTopVerilogSyn"
	mv ExampleTop.v ExampleTop.syn.v

sim: submodule sw
	sbt "runMain example.ExampleTopVerilogSim"
	mv ExampleTop.v ExampleTop.sim.v


#waves:
#	gtkwave -o simWorkspace/PanoCoreDut/test.vcd &
    
