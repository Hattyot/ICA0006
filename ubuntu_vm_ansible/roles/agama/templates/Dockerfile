FROM ubuntu:focal

ENV TZ=Europe/Tallinn
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update -y && \
    apt-get install python3-flask-sqlalchemy python3-pymysql wget mysql-server -y && \
    apt clean -y && \
    mkdir /agama && \
    wget -O/agama/agama.py https://raw.githubusercontent.com/hudolejev/agama/master/agama.py

ENV AGAMA_DATABASE_URI=sqlite:////agama/db.sqlite3
ENV FLASK_APP=agama

EXPOSE 8000/tcp

WORKDIR /agama

CMD ["flask", "run", "--host", "0.0.0.0", "--port", "8000"]
