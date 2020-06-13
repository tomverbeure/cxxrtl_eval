
# Compile different Yosys versions for different versions of CXXRTL

cd ~/tools/yosys

#git checkout bf0f96b847a9738df10e2a549a53bddfa0d1346a
#make clean
#make config-clang
#echo "ENABLE_DEBUG := 1" >> Makefile.conf
#make -j $(nproc)
#cp yosys yosys-20200419
#
#git checkout 95c74b319b36f8cb950196c3e1d10c945629c1f5
#make clean
#make config-clang
#echo "ENABLE_DEBUG := 1" >> Makefile.conf
#make -j $(nproc)
#cp yosys yosys-20200422a
#
#git checkout cf14e186eb6c89696cd1db4b36697a4e80b6884a
#make clean
#make config-clang
#echo "ENABLE_DEBUG := 1" >> Makefile.conf
#make -j $(nproc)
#cp yosys yosys-20200422b
#
#git checkout a7f2ef6d34c4b336a910b3c6f3d2cc11da8a82b4
#make clean
#make config-clang
#echo "ENABLE_DEBUG := 1" >> Makefile.conf
#make -j $(nproc)
#cp yosys yosys-20200526
#
#git checkout 83f84afc0b617fe78fb7cfa31fb9d1cd202e22f2
#make clean
#make config-clang
#echo "ENABLE_DEBUG := 1" >> Makefile.conf
#make -j $(nproc)
#cp yosys yosys-20200608

git checkout 971a7651555651e569311c6cbe039f0eee8cde93
make clean
make config-clang
echo "ENABLE_DEBUG := 1" >> Makefile.conf
make -j $(nproc)
cp yosys yosys-20200613
