#!/usr/bin/env python3
import argparse
import json
import socket
import time
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CourseDrop LAN discovery mock peer")
    parser.add_argument("--host", default="0.0.0.0", help="UDP bind host, default: 0.0.0.0")
    parser.add_argument("--port", type=int, default=39091, help="UDP discovery port, default: 39091")
    parser.add_argument("--device-id", default="pc-mock-001", help="Mock device id")
    parser.add_argument("--name", default="PC Mock Device", help="Mock device name")
    parser.add_argument("--platform", default="WINDOWS", help="Mock platform")
    parser.add_argument("--pairing-port", type=int, default=39092, help="Mock pairing port")
    parser.add_argument("--transfer-port", type=int, default=39092, help="Mock transfer port")
    parser.add_argument("--fingerprint", default="mock1234", help="Mock public key fingerprint")
    return parser.parse_args()


def decode_payload(data: bytes) -> dict[str, Any] | None:
    try:
        text = data.decode("utf-8", errors="replace").strip()
        if not text.startswith("{"):
            return None
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed
        return None
    except json.JSONDecodeError:
        return None


def build_announce(args: argparse.Namespace) -> bytes:
    payload = {
        "protocol": "coursedrop.discovery.v1",
        "kind": "ANNOUNCE",
        "deviceId": args.device_id,
        "deviceName": args.name,
        "platform": args.platform,
        "responsePort": args.port,
        "pairingPort": args.pairing_port,
        "transferPort": args.transfer_port,
        "capabilities": ["pairing-v1", "secure-transfer-v1"],
        "publicKeyFingerprint": args.fingerprint,
        "sentAt": int(time.time() * 1000),
    }
    return json.dumps(payload, separators=(",", ":")).encode("utf-8")


def main() -> None:
    args = parse_args()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.bind((args.host, args.port))
    sock.settimeout(0.5)

    print(f"CourseDrop LAN mock peer listening on udp://{args.host}:{args.port}")
    print("Press Ctrl+C to stop.")

    try:
        while True:
            try:
                data, addr = sock.recvfrom(65535)
            except socket.timeout:
                continue
            payload = decode_payload(data)
            preview = data[:240].decode("utf-8", errors="replace")
            print(f"\nrecv from {addr}: {preview}")

            if payload is None:
                print("skip: not a JSON discovery payload")
                continue
            if payload.get("protocol") != "coursedrop.discovery.v1":
                print("skip: protocol mismatch")
                continue
            if payload.get("kind") not in ("DISCOVER", "ANNOUNCE"):
                print("skip: kind mismatch")
                continue
            if payload.get("kind") != "DISCOVER":
                print("skip: not a DISCOVER request")
                continue

            response_port = payload.get("responsePort")
            if not isinstance(response_port, int) or response_port <= 0:
                response_port = args.port
            target = (addr[0], response_port)
            sock.sendto(build_announce(args), target)
            print(f"sent ANNOUNCE to {target[0]}:{target[1]}")
    except KeyboardInterrupt:
        print("\nstopped")
    finally:
        sock.close()


if __name__ == "__main__":
    main()
