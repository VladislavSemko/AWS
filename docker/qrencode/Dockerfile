FROM debian:9

ENV http_proxy http://172.20.13.183:3128 
ENV https_proxy http://172.20.13.183:3128 

RUN apt update -y
RUN apt install -y apt-utils git-core qrencode python-virtualenv
RUN git clone https://github.com/chubin/qrenco.de
RUN cd qrenco.de && virtualenv ve 
RUN cd qrenco.de && ve/bin/pip install -r requirements.txt

EXPOSE 8003
CMD cd qrenco.de && ve/bin/python bin/srv.py 
