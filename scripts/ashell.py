#!/usr/bin/env python3
"""Talk to the Android shell over the first VirtIO console.

The LineageOS wiki, "Text consoles":
  first serial console  -> GRUB + kernel messages
  first VirtIO console  -> Android shell environment   <-- this
  second VirtIO console -> logcat

Works without adb, so it is usable before setup/authorization is done.
"""
import socket, sys, time, os
os.makedirs('/tmp/android16', exist_ok=True)

SOCK = '/tmp/android16/shell.sock'


def run(cmd, wait=2.5, bufsize=262144):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(10)
    s.connect(SOCK)
    time.sleep(0.4)
    s.setblocking(False)
    try:
        s.recv(bufsize)
    except Exception:
        pass
    s.setblocking(True)
    # newline first in case a prompt is waiting
    s.sendall(b'\n' + cmd.encode() + b'\n')
    time.sleep(wait)
    out = b''
    s.setblocking(False)
    for _ in range(12):
        try:
            chunk = s.recv(bufsize)
            if not chunk:
                break
            out += chunk
        except Exception:
            time.sleep(0.25)
    s.close()
    return out.decode(errors='replace')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: ashell.py "<shell command>"')
        sys.exit(1)
    w = 2.5
    if sys.argv[1] == '-w':
        w = float(sys.argv[2])
        cmd = ' '.join(sys.argv[3:])
    else:
        cmd = ' '.join(sys.argv[1:])
    print(run(cmd, wait=w))
