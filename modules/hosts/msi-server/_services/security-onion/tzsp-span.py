import socket
import struct
import sys
import time

TZSP_VERSION = 1
TZSP_ENCAP_ETHERNET = 1
TZSP_TAG_PADDING = 0
TZSP_TAG_END = 1

ETHERTYPE_VLAN = 0x8100
ETHERTYPE_IPV4 = 0x0800
ETHERTYPE_IPV6 = 0x86DD
PROTO_TCP = 6
PROTO_UDP = 17
CHECKSUM_OFFSET = {PROTO_TCP: 16, PROTO_UDP: 6}
MAX_WIRE_FRAME = 1514


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


def checksum(data):
    if len(data) % 2:
        data += b"\0"
    total = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    while total > 0xFFFF:
        total = (total & 0xFFFF) + (total >> 16)
    return ~total & 0xFFFF


def l4_segment(frame):
    offset = 14
    (ethertype,) = struct.unpack_from("!H", frame, 12)
    if ethertype == ETHERTYPE_VLAN:
        (ethertype,) = struct.unpack_from("!H", frame, 16)
        offset = 18

    if ethertype == ETHERTYPE_IPV4:
        header_len = (frame[offset] & 0x0F) * 4
        (total_len,) = struct.unpack_from("!H", frame, offset + 2)
        (fragment,) = struct.unpack_from("!H", frame, offset + 6)
        if fragment & 0x3FFF:
            return None
        proto = frame[offset + 9]
        start = offset + header_len
        length = total_len - header_len
        addresses = frame[offset + 12:offset + 20]
        pseudo = addresses + struct.pack("!xBH", proto, length)
    elif ethertype == ETHERTYPE_IPV6:
        (length,) = struct.unpack_from("!H", frame, offset + 4)
        proto = frame[offset + 6]
        start = offset + 40
        addresses = frame[offset + 8:offset + 40]
        pseudo = addresses + struct.pack("!I3xB", length, proto)
    else:
        return None

    if proto not in CHECKSUM_OFFSET or start + length > len(frame):
        return None
    return pseudo, start, length, proto


def fix_checksum(frame):
    # R1 copies packets after GRO has merged them, and nothing recomputes
    # the checksum of a merged packet. Zeek and Suricata discard them.
    segment = l4_segment(frame)
    if segment is None:
        return frame
    pseudo, start, length, proto = segment
    frame = bytearray(frame)
    field = start + CHECKSUM_OFFSET[proto]
    frame[field:field + 2] = b"\0\0"
    value = checksum(pseudo + bytes(frame[start:start + length]))
    if proto == PROTO_UDP and value == 0:
        value = 0xFFFF
    struct.pack_into("!H", frame, field, value)
    return bytes(frame)


def main():
    port = int(sys.argv[1])
    interface = sys.argv[2]

    out = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    out.bind((interface, 0))

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 16 * 1024 * 1024)
    sock.bind(("0.0.0.0", port))

    dropped = 0
    last_report = 0.0
    while True:
        frame = ethernet_frame(sock.recv(65535))
        if frame is None or len(frame) < 14:
            continue
        if len(frame) > MAX_WIRE_FRAME:
            frame = fix_checksum(frame)
        try:
            out.send(frame)
        except OSError as e:
            dropped += 1
            now = time.monotonic()
            if now - last_report >= 60:
                last_report = now
                print(
                    f"dropped {dropped} frames so far, "
                    f"last {len(frame)} bytes: {e}",
                    file=sys.stderr,
                )


if __name__ == "__main__":
    main()
