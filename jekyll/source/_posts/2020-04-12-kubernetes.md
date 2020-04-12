---
layout: post
title: "Matando moscas a Kañonazos"
permalink: matando-moscas-kannonazos
date: 2020-04-12 06:39:50
comments: true
description: "Matando moscas a cañonazos, usando herramientas avanzadas del Mundo Devops, como Docker,TravisCI y Kubernetes."
keywords: "devops, developer, software"
comments: false
categories:
tags:
image: /images/rudder.jpg
summary: En el ciclo de desarrollo que seguimos para construir la aplicación de nuestros sueños, nos encontramos situaciones en las que tenemos que recurrir a la ardua labor de la depuración. Cuando el comportamiento de un componente software comienza a desafiar la lógica seguida en su implementación o cuando se llegan a dar casos límites que en un principio eran imposibles.

---

Quizá al leer este articulo, no noten gran diferencia en la web, sigue siendo tan simple, y corta de contenidos como siempre, (no nos engañemos). Pero creedme que esto ha cambiado, y mucho. 
Si queréis conocer las cosas que han cambiado, os invito a leer el post completo. 

Una de las primeras cosas que me enseñaron en el mundo de la informática, es que debemos evitar "matar moscas a cañonazos". 
Pero que ocurre si quiero probar el funcionamiento de un cañon, en ese caso mejor que sea con moscas.
Otro dicho frase que me viene a la cabeza, al escribir este post, es "los experimentos con gaseosa".

Como habéis podido comprobar, no me caracterizo por escribir continuamente, y la diferencia entre las fechas de publicaciones, distan meses. Como todos somos conscientes todos atravezamos una temporada un diferentes a causa del virus COVI-19 y más acusada la situación en unos días que normalmente son bien aprovechados para viajar o reunirnos con la familia.

Así que despues de tanto tiempo sin escribir nada, este fin de semana, me senté en el ordenador decidido a escribir algo, (sin saber muy bien que cosa...).

Al descargarme el repositorio fuente del blog, mi fuerza de voluntád empezó a flojear, al recordad que uso "Jekyll" y eso significa que voy a tener que instalar un monton de cosas relacionadas con el ecosistema de Ruby. Siendo un lenguage en el que no suelo desarrollar, me da gran pereza ensuiciar mi recien formateado ordenador, con multitud de dependencias y paquetes, que poco voy a aprovechar. 

Despues de sopesarlo un momento, pienso que lo mejor es Dockerizar el proyecto, y así ya no voy a volverme a tener que pelear instalando dependencias de Rubi. 

## Dockerizando mi blog.

Lo primero que me interesa es poder desarrollar en local, aislando las dependencias, y que sea autoinstalable.
Antes de nada paso a reestructurar los directorios, y de paso limpiar ficheros que no se usan. 
Importante añadir al .gitignore el direcotrio "site", con los compilados. 


{% highlight sh %}
FROM jekyll/builder

RUN apk update && apk add --update nodejs nodejs-npm
WORKDIR /app/jekyll

COPY entrypoint.sh /entrypoint
RUN sed -i 's/\r//' /entrypoint
RUN chmod +x /entrypoint


ENTRYPOINT ["/entrypoint"]
{% endhighlight %}

Al ser una versión para desarrollo, me ha parecido más cómodo hacer la instalación de dependencias
en tiempo de ejecución ``entrypoint``.

{% highlight sh %}
#!/bin/sh

set -o errexit
set -o nounset

bundle install

exec "$@"
{% endhighlight %}

Soy consciente que mi memoria es bastante limitada, por ello me creo un docker-compose para desarrollo, 
así ya no tengo que estar recordando las diferentes opciones, volumnes y puertos que debo añadir al arrancar el contenedor.
La orden a invovar es "jekyll serve" (para el servidor de pruebas) y el puerto 4000.

{% highlight sh %}
version: '3'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:80"
    volumes:
      - "./jekyll:/app/jekyll/"
    ports:
      - 4000:4000
    command: jekyll serve
{% endhighlight %}

Con ello ya, estaría, ya puedo escribir mi post, sin tener que preocuparme por instalar dependencias. 
Pero ya puestos no me puedo quedar aquí, y pienso en crear una imágen que en un futuro pueda usar para desplegar la aplicación en producción, almacenandola en algún registry como Docker Hub.

Despues de pensar un poco, creo que la opción más limpia es usar "multi-stage".
Y como podemos ver a continuación, el primer stage, se ocupa de hacer la compilación, 
y el segundo stage, es un servidor nginx alpine, con ello consigo que la imágen Docker pese menos de 14 MB.

{% highlight sh %}
FROM jekyll/builder as builder

RUN apk update && apk add --update nodejs nodejs-npm
WORKDIR /app/jekyll
COPY ./jekyll/Gemfile* /app/jekyll/
RUN bundle install
COPY ./jekyll /app/jekyll/
RUN mkdir -p /app/jekyll/_site && jekyll build

FROM nginx:alpine

RUN rm -f /etc/nginx/conf.d/* && rm -rf /app/*
COPY --from=builder /app/jekyll/_site /app
COPY ./nginx/default.conf /etc/nginx/conf.d/
{% endhighlight %}


Pero, ya no me puedo quedar quiero, ¿y si trato de desplegar?

## Kubernetes

Hace un tiempo, estuve haciendo un curso de Kubernetes y aún mantengo la instalación de "Minikube". Por tanto, es una buena oportunudad de probar.

Empezamos creando un **Deployment** y un **Service** básico en el fichero ``josemlp91-myblog.yml``.

{% highlight sh %}

apiVersion: v1
kind: Service
metadata:
  name: josemlp91-myblog
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: josemlp91-myblog
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: josemlp91-myblog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: josemlp91-myblog
  template:
    metadata:
      labels:
        app: josemlp91-myblog
    spec:
      containers:
      - name: josemlp91-myblog
        image: josemlp91/myblog:latest
        ports:
        - containerPort: 80

{% endhighlight %}

{% highlight sh %}
kubectl create -f josemlp91-myblog.yml
{% endhighlight %}

Y veo que funciona. Subidon de adrenalina. 

En este punto ya no me puedo quedár aquí despues de darle algunas vueltas,
decido empezar a buscar un cluster K8S en la nueve, donde hacer mi experimento, 
lo primero que se me ocurre es tirar de Amazon, Google Cloud o Azure. Además alguno de ellos ofrece credito de forma gratuita para hacer pruebas. Pero creo que hay que darle un puntito más de emoción de la cosa, y tratar de instalar un cluster kubernetes, puede ser un buen reto. (estoy confinado en casa y tengo tengo todo el puente...).

Comienzo a comparar diferentes proveedores de Servidores Cloud VPS, y consigo encontrar uno que me convence en relación calidad precio. Teniendo en cuenta que necesito tener dos, como mínimo (nodo máster y un worker), y que el master debe tener 2GB de RAM y 2 cores. 

Con mis flamantes máquinas, comienzo a instalar todo, ne me extiendo en explicar el proceso, dado que es largo.
Dejo las fuentes que he seguido.

Y este seria el resultado.

![](/images/nodes.png)


