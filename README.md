# docker-nfqueue-scapy

Docker container with an example python script to listen for packets on
a netfilter queue and manipulate them with scapy. You can listen on any queue number, and you can push packets into the queue from any iptables rule. 
This container gives you a powerful prototyping and debugging tool for monitoring, manipulating, dropping, accepting, requeing, or forwarding network packets in python.
You can read from a queue on the host with `--net=host --cap-add=NET_ADMIN`.
 Or, you can run it within another container's namespace to listen
for packets on an nfqueue in that container's network namespace.

This container includes a full installation of scapy and python netfilter queue
(nfqueue) bindings, and an example python script `nfqueue_listener.py` to
print incoming packets on the queue.

scapy: https://github.com/secdev/scapy
python-netfilterqueue: https://github.com/kti/python-netfilterqueue

## How to use

Clone this repository

``` shell
git clone git@github.com:milesrichardson/docker-nfqueue-scapy.git
```

Build the docker container. This will take a while because it includes the
full scapy install and all its dependencies. You can use any tag you want, but
as an example here I'm using `nfqueuelistener`

``` shell
cd docker-nfqueue-scapy
sudo docker build . -t nfqueuelistener
```

(Example)

Use `iptables` on the host to send TCP packets destined for port `9001`
to nfqueue `1`:

``` shell
sudo iptables -t raw \
              -A PREROUTING \
              -p tcp --destination-port 9001 \
              -j NFQUEUE --queue-num 1
```

Run the docker container to listen for packets and print then accept any
received packets.

``` shell
sudo docker run -it --rm \
                --cap-add=NET_ADMIN \
                --net=host \
                --name=nfqueuelistener nfqueuelistener
```

From another machine, send some packets to test:

``` shell
echo "Hello" | nc -v $HOST_IP_ADDRESS 9001
```

You should see something like this:

``` shell
miles@box:~/testing$ sudo docker run -it --rm --cap-add=NET_ADMIN --net=host --name=nfqueuelistener nfqueuelistener
Listening on NFQUEUE queue-num 1...
<IP  version=4L ihl=5L tos=0x0 len=64 id=6387 flags=DF frag=0L ttl=55 proto=tcp chksum=0x6850 src=11.22.33.44 dst=44.55.66.77 options=[] |<TCP  sport=58164 dport=9001 seq=4038873318 ack=0 dataofs=11L reserved=0L flags=S window=65535 chksum=0x67be urgptr=0 options=[('MSS', 1452), ('NOP', None), ('WScale', 5), ('NOP', None), ('NOP', None), ('Timestamp', (2615879909, 0)), ('SAckOK', ''), ('EOL', None)] |>>
```

## Setting the queue number

The default queue number is `1`. You can override this by setting the environment variable
`QUEUE_NUM` when running the container. For example, for queue `2`:

``` shell
sudo docker run -it --rm \
                -e 'QUEUE_NUM=2' \
                --cap-add=NET_ADMIN \
                --net=host \
                --name=nfqueuelistener nfqueuelistener
```

## Editing the `nfqueue_listener.py` file

One way to edit the `nfqueue_listener.py` file is to simply edit it and then rebuild
the container with `sudo docker build . -t nfqueuelistener`. Since you are only
editing the python file, building will not take as long as the first build.

You can find the documentation for the nfqueue library used at https://github.com/kti/python-netfilterqueue

## Listening in another container's namespace

I have not tested this, but it should work.

Say you have another container `$CONTAINER_ID` and you want to intercept incoming
packets in its namespace. You can run this docker container like:

``` shell
sudo docker run -it --rm \
                --net=container:$CONTAINER_ID \
                --name=nfqueuelistener nfqueuelistener
```

Note that you will need to run your `iptables` rules to send packets to the queue
from within the `$CONTAINER_ID` container.

## Other notes

scapy is hardcoded version `2.3.2` because there is a bug in `2.3.3` causing
scapy to fail on openstack deployments. The bug is actually upstream in openstack,
and has been fixed, but this caused problems for me testing on packet.net where
they have apparently not updated openstack yet.
