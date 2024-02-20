# Looking for information on environment variables?
# We don't declare them here — take a look at our docs.
# https://github.com/swagger-api/swagger-ui/blob/master/docs/usage/configuration.md

ARG NODE_VERSION

###

FROM node:$NODE_VERSION AS builder

ARG PROJ_PATH
WORKDIR /src/$PROJ_PATH
COPY $PROJ_PATH/package.json .
COPY $PROJ_PATH/package-lock.json .
RUN npm install
COPY $PROJ_PATH .

##

FROM builder AS dist
RUN npm run build

# ###

FROM nginx:1.25.4-alpine AS app

RUN apk add "nodejs"

LABEL maintainer="char0n"

ENV API_KEY="**None**" \
    SWAGGER_JSON="/app/swagger.json" \
    PORT="8080" \
    PORT_IPV6="" \
    BASE_URL="/" \
    SWAGGER_JSON_URL="" \
    CORS="true" \
    EMBEDDING="false"

COPY --chown=nginx:nginx --chmod=0666 ./docker/default.conf.template ./docker/cors.conf ./docker/embedding.conf /etc/nginx/templates/

COPY --chmod=0666 --from=dist src/dist/* /usr/share/nginx/html/
COPY --chmod=0555 ./docker/docker-entrypoint.d/ /docker-entrypoint.d/
COPY --chmod=0666 ./docker/configurator /usr/share/nginx/configurator

# Simulates running NGINX as a non root; in future we want to use nginxinc/nginx-unprivileged.
# In future we will have separate unpriviledged images tagged as v5.1.2-unprivileged.
RUN chmod 777 /usr/share/nginx/html/ /etc/nginx/conf.d/ /etc/nginx/conf.d/default.conf /var/cache/nginx/ /var/run/

EXPOSE 8080

###

FROM builder AS test

CMD npm run start > /dev/null 2>&1 &
