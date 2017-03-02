#! /usr/bin/env python2.7

from scapy.all import IP
from netfilterqueue import NetfilterQueue
import socket
from pprint import pprint
import json
import os
import sys
import logging

try:
    QUEUE_NUM = int(os.getenv('QUEUE_NUM', 1))
except ValueError as e:
    sys.stderr.write('Error: env QUEUE_NUM must be integer\n')
    sys.exit(1)

def callback(pkt):

    try:
        packet = IP(pkt.get_payload())

        pprint(packet)

        pkt.accept()
    except Exception as e:
        print 'Error: %s' % str(e)

        pkt.drop()

sys.stdout.write('Listening on NFQUEUE queue-num %s... \n' % str(QUEUE_NUM))

nfqueue = NetfilterQueue()
nfqueue.bind(QUEUE_NUM, callback)
s = socket.fromfd(nfqueue.get_fd(), socket.AF_UNIX, socket.SOCK_STREAM)
try:
    nfqueue.run_socket(s)
except KeyboardInterrupt:
    sys.stdout.write('Exiting \n')

s.close()
nfqueue.unbind()
