#!/usr/bin/env python3
"""Drive the QEMU monitor: send keys, capture the screen as PNG."""
import socket, sys, time, os
os.makedirs('/tmp/android16', exist_ok=True)

SOCK = '/tmp/android16/qemu-mon.sock'

def cmd(c, wait=0.6):
    s = socket.socket(socket.AF_UNIX); s.settimeout(8); s.connect(SOCK)
    time.sleep(0.4)
    try: s.recv(65536)
    except Exception: pass
    s.sendall(c.encode() + b'\n')
    time.sleep(wait)
    try: out = s.recv(65536).decode(errors='replace')
    except Exception: out = ''
    s.close(); return out

def shot(png='/tmp/android16/shot.png'):
    ppm = '/tmp/android16/_shot.ppm'
    if os.path.exists(ppm): os.remove(ppm)
    cmd(f'screendump {ppm}', wait=3.5)
    for _ in range(10):
        if os.path.exists(ppm) and os.path.getsize(ppm) > 1000: break
        time.sleep(0.5)
    from PIL import Image
    Image.open(ppm).save(png)
    return png

if __name__ == '__main__':
    a = sys.argv[1:]
    if not a: print('usage: qmon.py key <k>... | shot [png] | cmd <text>'); sys.exit(1)
    if a[0] == 'key':
        for k in a[1:]:
            cmd(f'sendkey {k}', wait=0.35); print('sent', k)
    elif a[0] == 'shot':
        print(shot(a[1] if len(a) > 1 else '/tmp/android16/shot.png'))
    else:
        print(cmd(' '.join(a[1:]) if a[0] == 'cmd' else ' '.join(a)))
