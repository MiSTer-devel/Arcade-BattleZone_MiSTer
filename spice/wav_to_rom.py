#!/usr/bin/python3

import wave, struct
import argparse
import itertools

def write_rom(wav_file, var_name):
    with wave.open(wav_file, 'r') as wav:
        frames = wav.readframes(48000);
        samples = struct.unpack(f'<{48000}h', frames)
        with open(f'{wav_file}.sv', 'w') as rom:
            rom.writelines([f'{var_name}[{i}]={line + 32768};\n'  for i, line in enumerate(samples)])

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("wav_file")
	parser.add_argument("var_name")
	args = parser.parse_args()

	write_rom(args.wav_file, args.var_name)