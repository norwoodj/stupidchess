FROM python:3.7.3-slim
LABEL maintainer=norwood.john.m@gmail.com

COPY server/Pipfile server/Pipfile.lock ./
RUN pip install --upgrade \
        pip \
        pipenv \
        setuptools \
        wheel \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
    && pipenv install --system

ARG APP_DIR=/var/lib/johnmalcolmnorwood/stupidchess/server
WORKDIR ${APP_DIR}

COPY server/packages .

RUN cd auth && pip install .
RUN cd stupidchess && pip install .

COPY server/config ./config
COPY etc/uwsgi/uwsgi.ini /etc/uwsgi/uwsgi.ini

ENTRYPOINT ["uwsgi", "--ini", "/etc/uwsgi/uwsgi.ini"]
