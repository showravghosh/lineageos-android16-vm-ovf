#!/usr/bin/env python3
"""Root shell on the Android serial console.

Requires `serial_console_function=console` in grubenv (LineageOS boot menu:
Settings -> Serial console function -> Console) and QEMU started with
  -serial unix:/tmp/android16/console.sock,server=on,wait=off
"""
import socket, sys, time, os
os.makedirs('/tmp/android16', exist_ok=True)

SOCK = '/tmp/android16/console.sock'


def run(cmd, wait=3.0):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(12)
    s.connect(SOCK)
    time.sleep(0.5)
    s.setblocking(False)
    try:
        s.recv(1 << 20)
    except Exception:
        pass
    s.setblocking(True)
    s.sendall(b'\n')
    time.sleep(0.6)
    s.setblocking(False)
    try:
        s.recv(1 << 20)
    except Exception:
        pass
    s.setblocking(True)
    # marker makes it easy to find the output in the stream
    s.sendall(b'echo __S__; ' + cmd.encode() + b'; echo __E__\n')
    time.sleep(wait)
    out = b''
    s.setblocking(False)
    for _ in range(20):
        try:
            c = s.recv(1 << 20)
            if not c:
                break
            out += c
            if b'__E__' in out:
                break
        except Exception:
            time.sleep(0.3)
    s.close()
    t = out.decode(errors='replace')
    if '__S__' in t and '__E__' in t:
        t = t.split('__S__', 1)[1].rsplit('__E__', 1)[0]
    return t.strip()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: console.py "<command>" [wait_seconds]')
        sys.exit(1)
    w = float(sys.argv[2]) if len(sys.argv) > 2 else 3.0
    print(run(sys.argv[1], w))
