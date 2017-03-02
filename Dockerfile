FROM ubuntu:latest
MAINTAINER milesrichardson@gmail.com

# Install latest scapy (with all its dependencies)

RUN apt-get update && \
    apt-get install -y \
    zip \
    unzip \
    python \
    python-pyx \
    python-matplotlib \
    tcpdump \
    python-crypto \
    graphviz \
    imagemagick \
    gnuplot \
    python-gnuplot \
    libpcap-dev && apt-get clean

ADD https://github.com/secdev/scapy/archive/master.zip /tmp/master.zip
RUN unzip /tmp/master.zip -d /usr/local/ && rm /tmp/master.zip

RUN apt-get update && \
    apt-get -qq -y install \
    bridge-utils \
    net-tools \
    iptables \
    python \
    tcpdump \
    build-essential \
    python-dev \
    libnetfilter-queue-dev \
    python-pip

RUN pip install scapy==2.3.2
RUN pip install NetfilterQueue

# Force matplotlib to generate the font cache
RUN python -c 'import matplotlib.pyplot'

ADD ./nfqueue_listener.py /nfqueue_listener.py

ENV QUEUE_NUM=1

ENTRYPOINT python nfqueue_listener.py
