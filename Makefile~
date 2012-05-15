.SUFFIXES: .erl .beam

.erl.beam:
	erlc -W $<

MODS = engine err_man win_man node

ERL = erl -noshell

all: compile

compile: ${MODS:%=%.beam}

testuni: compile
	${ERL} -s engine starter uni.dat

testint: compile
	${ERL} -s engine starter int.dat

clean:
	rm -rf *.beam erl_crash.dump
	rm -rf nodes2.dat
	rm -rf nodes.dat
 
watch: compile
	./starter.sh

