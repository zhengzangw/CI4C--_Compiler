import json
import sys
from os import system, pipe, close


def msg(s):
    print('\033[1m\033[91m' + s + '\033[0m\033[0m')


def err(data_in, data_out, s):
    msg("Wrong on input " + str(data_in) + "\n" +
        "Output mismatch, your output is " + str(s) + "\n" + "Output should be: " + str(data_out))
    exit(1)


f_json = sys.argv[1]
f_ir = sys.argv[2]
program = "spim -file"
irsim_in = 'CI4C--_Compiler/workdir/irsim_in'
irsim_out = 'CI4C--_Compiler/workdir/irsim_out'

for data_in, data_out, ret_val in json.load(open(f_json)):
    with open(irsim_in, 'w+') as to_irsim_w:
        for i in data_in:
            to_irsim_w.write(str(i) + '\n')

    ret = system("%s %s < %s > %s 2>/dev/null" %
                 (program, f_ir, irsim_in, irsim_out))
    # Runtime error
    if ret != 0:
        err(data_in, data_out, "Runtime error occured when running your mips code")
        # Output mismatch
    with open(irsim_out, 'r') as from_irsim_r:
        # Filter out the line above "Loaded: ./workdir/a.ir"
        temp_str = from_irsim_r.readline()
        while temp_str[:6] != "Loaded":
            temp_str = from_irsim_r.readline()
        your_output = []
        try:
            temp_str = from_irsim_r.readline()
            while temp_str != '':
                while temp_str[:5] == "Enter":
                    temp_str = temp_str[17:]
                if temp_str == '':
                    continue
                your_output.append(int(temp_str))
                temp_str = from_irsim_r.readline()

            if len(data_out) != len(your_output):
                raise ValueError
            for i in range(len(data_out)):
                if data_out[i] != your_output[i]:
                    raise ValueError
            # if temp_str != "ret with 0, reason 0\n":
            #    raise ValueError
        except ValueError:
            err(data_in, data_out, your_output)

exit(0)
