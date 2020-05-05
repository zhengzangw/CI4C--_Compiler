import json
import sys
from os import system, pipe, close


def msg(s):
    print('\033[1m\033[91m' + s + '\033[0m\033[0m')


def err(data_in, s):
    msg("Wrong on input " + str(data_in) + "\n" + s)
    exit(1)


f_json = sys.argv[1]
f_ir = sys.argv[2]
program = "irsim/build/irsim"
irsim_in  = 'CI4C--_Compiler/workdir/irsim_in'
irsim_out = 'CI4C--_Compiler/workdir/irsim_out'
num_file = 'CI4C--_Compiler/workdir/count'

for data_in, data_out, ret_val in json.load(open(f_json)):
    with open(irsim_in, 'w+') as to_irsim_w:
        for i in data_in:
            to_irsim_w.write(str(i) + '\n')

    ret = system("%s %s < %s > %s 2>/dev/null"%(program, f_ir , irsim_in , irsim_out))
    # Suppose irsim is compiled by run.sh
    if ret != 0:
        err(data_in, "Runtime error occured when running your IR code");
    with open(irsim_out, 'r') as from_irsim_r:
        from_irsim_r.readline()
        # Filter out the first line "load ./workdir/a.ir"
        try:
            for i in data_out:
                if i != int(from_irsim_r.readline()):
                    err(data_in, "Output mismatch (output wrong number(s))")
            else:
                if "ret with 0, reason 0\n" != from_irsim_r.readline():
                    err(data_in, "Output mismatch (output more number(s))")
                cnt = int(from_irsim_r.readline())
                with open(num_file, "r") as f:
                    cnt = cnt + int(f.read())
                with open(num_file, "w") as f:
                    f.write(str(cnt))
        except ValueError:
            err(data_in, "Output mismatch (output less number(s))")

exit(0)
