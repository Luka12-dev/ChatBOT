# tools/convert_model.py
import argparse
import os
import subprocess

def convert(src, out, quant='int8'):
    # Primer: ovde pozivas stvarne alate za konverziju (local)
    print(f'Pretvaram {src} -> {out} kvantizacija {quant}')
    # ovde mozes dodati poziv lokalnih alata, npr. llama.cpp converter, ggml tools itd.
    # subprocess.run(['python', 'convert_tool.py', src, out, '--quant', quant], check=True)
    print('Done (stub)')

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('--src', required=True, help='Path to original model file')
    p.add_argument('--out', required=True, help='Path to output quantized model')
    p.add_argument('--q', default='int8')
    args = p.parse_args()
    convert(args.src, args.out, args.q)