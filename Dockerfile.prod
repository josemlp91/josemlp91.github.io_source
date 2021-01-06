FROM jekyll/builder as builder

RUN apk update && apk add --update nodejs nodejs-npm
WORKDIR /app/jekyll
COPY ./jekyll/Gemfile* /app/jekyll/
RUN bundle install
COPY ./jekyll /app/jekyll/
RUN mkdir -p /app/jekyll/_site && jekyll build

FROM bitnami/nginx

COPY --from=builder /app/jekyll/_site /app
CMD ["nginx", "-g", "daemon off;"]