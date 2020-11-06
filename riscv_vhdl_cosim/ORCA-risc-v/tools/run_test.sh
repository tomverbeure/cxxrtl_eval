
if [ $# -ne 1 ]
then
echo "USAGE $0 <test.hex>" >&2
exit 1
fi
i=$1
if [ -f $i ]
then
cp $i test.hex
quartus_cdb --update_mif vblox1.qpf
quartus_asm vblox1.qpf
quartus_pgm -m JTAG -o P\;output_files/vblox1.sof
else
echo "No such file $1" >&2
exit 1
fi
