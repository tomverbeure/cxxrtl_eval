TEST_DIR=/nfs/scratch/riscv-tools/riscv-tests/isa
UFILES=$(ls $TEST_DIR/rv32ui-p-* | grep -v hex | grep -v dump)
#MFILES=$(ls $TEST_DIR/rv32mi-p-* | grep -v hex | grep -v dump)
FILES="$UFILES $MFILES"

#echo \$# = $#
if [ $# -eq 1 ]
then
	 ln -sf $1.mem test.mem
	 ln -sf $1.gex test.hex
	 touch test.mem test.hex
	 exit 0
fi

mkdir -p test
if which mif2hex >/dev/null
then
	 :
else
	 echo "cant find command mif2hex, exiting." >&2
	 exit -1;
fi

for f in $FILES
do
	 echo "$f > test/$(basename $f).gex"
	 (
		  BIN_FILE=test/$(basename $f).bin
		  GEX_FILE=test/$(basename $f).gex
		  MEM_FILE=test/$(basename $f).mem
		  MIF_FILE=test/$(basename $f).mif
		  SPLIT_FILE=test/$(basename $f).split2
		  cp $f test/
		  riscv64-unknown-elf-objcopy  -O binary $f $BIN_FILE
		  riscv64-unknown-elf-objdump --disassemble-all -Mnumeric,no-aliases $f > test/$(basename $f).dump
		  python ../tools/bin2mif.py $BIN_FILE 0x100 > $MIF_FILE || exit -1
		  mif2hex $MIF_FILE $GEX_FILE >/dev/null 2>&1 || exit -1
		  sed -e 's/://' -e 's/\(..\)/\1 /g'  $GEX_FILE >$SPLIT_FILE
		  awk '{if (NF == 9) print $5$6$7$8}' $SPLIT_FILE > $MEM_FILE
		  rm -f $MIF_FILE $SPLIT_FILE
	 ) &
done
wait
