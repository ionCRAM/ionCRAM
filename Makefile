all:
	cd src/io_lib && make
#	cd src/icram/ && make
	cd src/ioncram/ && make


install:
	cd src/io_lib/ && make install 
	cd src/ioncram/ && make install
clean:
	cd src/icram/ && make clean
	cd src/ioncram/ && make clean && ./configure clean
