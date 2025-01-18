ARG NODE_VERSION=18

FROM node:${NODE_VERSION} AS base

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

FROM base AS builder

WORKDIR /usr/src/app

RUN npm run dist && \
	chmod +x ./dist/*.AppImage && \
	./dist/*.AppImage --appimage-extract

FROM node:${NODE_VERSION}-slim

EXPOSE 8080

ARG WORKDIR=/usr/src/app

WORKDIR ${WORKDIR}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
	apt install -y \
	libxshmfence-dev \
	libnss3 \
	libatk1.0-dev \
	libatk-bridge2.0-dev \
	libdrm-dev \
	libgtk-3-dev \
	libasound-dev \
	xvfb

COPY --from=builder /usr/src/app/squashfs-root .

# https://github.com/Xzandro/sw-exporter/blob/4ab26d6f4cb875eb148388b33b5a3f7227cc6037/app/main.js#L34
RUN mkdir -p /root/Desktop/Summoners\ War\ Exporter\ Files/plugins

ADD https://github.com/Cerusa/swgt-swex-plugin/releases/download/2.0.5/SWGTLogger.asar /root/Desktop/Summoners\ War\ Exporter\ Files/plugins/

ENV APPDIR=${WORKDIR}
ENV port=8080
ENV autostart=true

WORKDIR ${APPDIR}

ENTRYPOINT [ "xvfb-run", "./AppRun", "--no-sandbox" ]
