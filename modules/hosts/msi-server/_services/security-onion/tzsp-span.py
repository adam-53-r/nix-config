import socket
import struct
import sys

TZSP_VERSION = 1
TZSP_ENCAP_ETHERNET = 1
TZSP_TAG_PADDING = 0
TZSP_TAG_END = 1


def ethernet_frame(packet):
    if len(packet) < 4 or packet[0] != TZSP_VERSION:
        return None
    (encapsulation,) = struct.unpack_from("!H", packet, 2)
    if encapsulation != TZSP_ENCAP_ETHERNET:
        return None
    i = 4
    while i < len(packet):
        tag = packet[i]
        if tag == TZSP_TAG_END:
            return packet[i + 1:]
        if tag == TZSP_TAG_PADDING:
            i += 1
        elif i + 1 < len(packet):
            i += 2 + packet[i + 1]
        else:
            return None
    return None


def main():
    port = int(sys.argv[1])
    interface = sys.argv[2]

    out = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    out.bind((interface, 0))

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 16 * 1024 * 1024)
    sock.bind(("0.0.0.0", port))

    while True:
        frame = ethernet_frame(sock.recv(65535))
        if frame is None:
            continue
        try:
            out.send(frame)
        except OSError:
            # Oversized or malformed frames; dropping one beats dying.
            continue


if __name__ == "__main__":
    main()
