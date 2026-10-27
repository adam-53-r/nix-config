import fcntl
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
TCP_FIN = 0x01
TCP_PSH = 0x08
MAX_WIRE_FRAME = 1514
SIOCGIFMTU = 0x8921


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
    ip_start = 14
    (ethertype,) = struct.unpack_from("!H", frame, 12)
    if ethertype == ETHERTYPE_VLAN:
        (ethertype,) = struct.unpack_from("!H", frame, 16)
        ip_start = 18

    if ethertype == ETHERTYPE_IPV4:
        header_len = (frame[ip_start] & 0x0F) * 4
        (total_len,) = struct.unpack_from("!H", frame, ip_start + 2)
        (fragment,) = struct.unpack_from("!H", frame, ip_start + 6)
        if fragment & 0x3FFF:
            return None
        proto = frame[ip_start + 9]
        start = ip_start + header_len
        length = total_len - header_len
    elif ethertype == ETHERTYPE_IPV6:
        (length,) = struct.unpack_from("!H", frame, ip_start + 4)
        proto = frame[ip_start + 6]
        start = ip_start + 40
    else:
        return None

    if proto not in CHECKSUM_OFFSET or start + length > len(frame):
        return None
    return ip_start, start, length, proto


def pseudo_header(frame, ip_start, length, proto):
    if frame[ip_start] >> 4 == 4:
        addresses = frame[ip_start + 12:ip_start + 20]
        return addresses + struct.pack("!xBH", proto, length)
    addresses = frame[ip_start + 8:ip_start + 40]
    return addresses + struct.pack("!I3xB", length, proto)


def fix_checksum(frame):
    # R1 copies packets after GRO has merged them, and nothing recomputes
    # the checksum of a merged packet. Zeek and Suricata discard them.
    segment = l4_segment(frame)
    if segment is None:
        return frame
    ip_start, start, length, proto = segment
    frame = bytearray(frame)
    field = start + CHECKSUM_OFFSET[proto]
    frame[field:field + 2] = b"\0\0"
    pseudo = pseudo_header(frame, ip_start, length, proto)
    value = checksum(pseudo + bytes(frame[start:start + length]))
    if proto == PROTO_UDP and value == 0:
        value = 0xFFFF
    struct.pack_into("!H", frame, field, value)
    return bytes(frame)


def set_ip_length(frame, ip_start, index):
    if frame[ip_start] >> 4 == 4:
        header_len = (frame[ip_start] & 0x0F) * 4
        (ident,) = struct.unpack_from("!H", frame, ip_start + 4)
        total_len = len(frame) - ip_start
        struct.pack_into("!H", frame, ip_start + 2, total_len)
        struct.pack_into("!H", frame, ip_start + 4, (ident + index) & 0xFFFF)
        struct.pack_into("!H", frame, ip_start + 10, 0)
        header = bytes(frame[ip_start:ip_start + header_len])
        struct.pack_into("!H", frame, ip_start + 10, checksum(header))
    else:
        payload_len = len(frame) - ip_start - 40
        struct.pack_into("!H", frame, ip_start + 4, payload_len)


def split_tcp(frame, mtu):
    # Merged packets can be bigger than span0's MTU. Cut them back into
    # segments that fit, as the sender would have sent them.
    segment = l4_segment(frame)
    if segment is None or segment[3] != PROTO_TCP:
        return []
    ip_start, start, length, _ = segment
    header_end = start + (frame[start + 12] >> 4) * 4
    payload = frame[header_end:start + length]
    room = mtu - (header_end - ip_start)
    if room <= 0:
        return []
    (seq,) = struct.unpack_from("!I", frame, start + 4)
    flags = frame[start + 13]

    pieces = []
    for index, pos in enumerate(range(0, len(payload), room)):
        piece = bytearray(frame[:header_end] + payload[pos:pos + room])
        struct.pack_into("!I", piece, start + 4, (seq + pos) & 0xFFFFFFFF)
        if pos + room < len(payload):
            piece[start + 13] = flags & ~(TCP_FIN | TCP_PSH)
        set_ip_length(piece, ip_start, index)
        pieces.append(fix_checksum(bytes(piece)))
    return pieces


def main():
    port = int(sys.argv[1])
    interface = sys.argv[2]

    out = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    out.bind((interface, 0))
    request = struct.pack("16si", interface.encode(), 0)
    reply = fcntl.ioctl(out, SIOCGIFMTU, request)
    (mtu,) = struct.unpack_from("i", reply, 16)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 16 * 1024 * 1024)
    sock.bind(("0.0.0.0", port))

    dropped = 0
    last_report = 0.0
    while True:
        frame = ethernet_frame(sock.recv(65535))
        if frame is None or len(frame) < 14:
            continue
        if len(frame) > mtu + 14:
            pieces = split_tcp(frame, mtu) or [frame]
        elif len(frame) > MAX_WIRE_FRAME:
            pieces = [fix_checksum(frame)]
        else:
            pieces = [frame]
        for piece in pieces:
            try:
                out.send(piece)
            except OSError as e:
                dropped += 1
                now = time.monotonic()
                if now - last_report >= 60:
                    last_report = now
                    print(
                        f"dropped {dropped} frames so far, "
                        f"last {len(piece)} bytes: {e}",
                        file=sys.stderr,
                    )


if __name__ == "__main__":
    main()
