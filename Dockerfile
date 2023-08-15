FROM erlang:26-alpine as builder

RUN mkdir /data
WORKDIR /data

COPY src src/
COPY rebar.config .
RUN rebar3 release

FROM alpine

RUN apk add --no-cache openssl libgcc libstdc++ ncurses-libs bash

COPY --from=builder /data/_build/default/rel/muncher /muncher
ENV TERM=xterm
EXPOSE 8443

CMD ["/bin/sh"]
