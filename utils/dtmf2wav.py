#!/usr/bin/python

import sys
import os
import getopt


def usage(err):
    out = sys.stdout
    if err:
        out = sys.stderr
    out.write(err)
    out.write("\n")
    out.write("""
This script writes a sequence of DTMF tones to a wav file
Usage: %(app)s [-p milliseconds] [-P milliseconds] [-i milliseconds] dtmf_sequence out_file
Ex:    %(app)s 1234567890abcd*# digits.wav

Details:
       -p | --pre-silence <milliseconds> (number of milliseconds of silence before dtmf audio sequence. 200 ms by default)
       -P | --post-silence <milliseconds> (number of milliseconds of silence after dtmf audio sequence. 200 ms by default)
       -d | --duration <milliseconds> (duration of each tone in milliseconds. 100 by default)
       -i | --interval <milliseconds> (duration of silence interval between tones in milliseconds. 100 by default)
""")


try:
    opts, args = getopt.getopt(sys.argv[1:], "p:P:d:i:h", ["pre-silence", "post-silence", "duration", "interval", "help"])
except getopt.GetoptError as err:
    usage(err)
    sys.exit(2)


pre_silence=0.2
post_silence=0.2
duration=0.1
interval=0.1

for o,a in opts:
    if o in ("-p", "--pre-silence"):
        pre_silence=int(a)/1000.0
    elif o in ("-P", "--post-silence"):
        post_silence=int(a)/1000.0
    elif o in ("-d", "--duration"):
        duration=int(a)/1000.0
    elif o in ("-i", "--interval"):
        interval=int(a)/1000.0
    elif o in ("-h", "--help"):
        usage()
        sys.exit(0)


if len(args) != 2:
    usage("Invalid number of arguments")
    sys.exit(1)

digits, out_file = args

       
dtmf_tones = {
        "1": {"low": 697, "high": 1209},
        "2": {"low": 697, "high": 1336},
        "3": {"low": 697, "high": 1477},
        "a": {"low": 697, "high": 1633},

        "4": {"low": 770, "high": 1209},
        "5": {"low": 770, "high": 1336},
        "6": {"low": 770, "high": 1477},
        "b": {"low": 778, "high": 1633},

        "7": {"low": 852, "high": 1209},
        "8": {"low": 852, "high": 1336},
        "9": {"low": 852, "high": 1477},
        "c": {"low": 852, "high": 1633},

        "*": {"low": 941, "high": 1209},
        "0": {"low": 941, "high": 1336},
        "#": {"low": 941, "high": 1477},
        "d": {"low": 941, "high": 1633},
}

pre_silence_sox_pipe = "|sox -np trim 0.0 %f rate 8000" % (pre_silence,)
post_silence_sox_pipe = "|sox -np trim 0.0 %f rate 8000" % (post_silence,)

interval_sox_pipe=" '|sox -np trim 0.0 %f rate 8000' " % (interval,)

tone_sox_pipe_template = "|sox -np synth 0.1 sine %(low)u sine %(high)u channels 1 rate 8000"

digits = digits.lower().replace("e","*").replace("f", "#")

tone_sox_pipes = [tone_sox_pipe_template % dtmf_tones[d] for d in digits]
tone_sox_pipes = ["'" + s + "'" for s in tone_sox_pipes]
tone_sox_pipes = interval_sox_pipe.join(tone_sox_pipes)

cmds = [
	"mkdir -p `dirname %s`" % (out_file,),
	"sox '%s' %s '%s' %s" % (pre_silence_sox_pipe, tone_sox_pipes, post_silence_sox_pipe, out_file)
]

for cmd in cmds:
	print "Executing: " + cmd

	res = os.system(cmd)

	if res != 0:
		sys.stderr.write("%s: failed\n" % (cmd,))
		sys.exit(1)

print "Success"

