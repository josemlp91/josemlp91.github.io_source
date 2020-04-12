---
layout: post
title: "Matando moscas a 'Kañonazos'"
date: 2020-04-12 06:39:50
comments: true
description: "Matando moscas a cañonazos, usando herramientas avanzadas del Mundo Devops, como Docker,TravisCI y Kubernetes."
keywords: "devops, developer, software"
comments: false
image: /images/rudder.jpg
summary: Quizá al leer este articulo, no noten gran diferencia en la web, sigue siendo tan simple, y corta de contenidos como siempre, (no nos engañemos). Pero creedme que esto ha cambiado, y mucho. Si queréis conocer las cosas que han cambiado, os invito a leer el post completo. 

---

![](/images/rudder-mini.jpg)

Una de las primeras cosas que me enseñaron en el mundo de la informática, es que debemos evitar "matar moscas a cañonazos". 
Otra frase que me viene a la cabeza, al escribir este post, es "los experimentos con gaseosa".

Como habéis podido comprobar, no me caracterizo por escribir continuamente, y la diferencia entre las fechas de publicaciones, distan meses.

Así que después de tanto tiempo sin escribir nada, este fin de semana, me senté en el ordenador decidido a escribir algo, (sin saber muy bien que cosa...), aprovechando que hay que quedarse en casa dada la situación que alerta que estamos sufriendo, por el COVID-19. 

Al descargarme el [repositorio](https://github.com/josemlp91/josemlp91.github.io_source) con el código fuente del blog, mi fuerza de voluntad empezó a flojear, al recordad que uso **"Jekyll"** y eso significa que voy a tener que instalar un montón de cosas relacionadas con el ecosistema de **Ruby**. Siendo un lenguaje de programación que no suelo utilizar, me da gran pereza emborronar mi recién formateado ordenador, con multitud de dependencias y paquetes, que poco voy a aprovechar. 

Después de sopesarlo un momento, pienso que lo mejor es **Dockerizar** el proyecto, y no volver a instalar dependencias de Jekyll. 

## Docker 🐋

Lo primero que me interesa es poder desarrollar en local, aislando las dependencias, y que sea *auto-instalable*.
Antes de nada paso a reestructurar los directorios y de paso limpiar ficheros que no se usan. 
Importante añadir al *.gitignore* el directorio "site", con los compilados. 

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

Mi memoria es bastante limitada, por ello me escribo un **docker-compose** para desarrollo, 
así ya no tengo que estar recordando las diferentes opciones, volúmenes y puertos que debo añadir al arrancar el contenedor.
La orden a invocar es ``jekyll serve`` (para el servidor de pruebas) y el puerto 4000.

{% highlight yaml %}
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
Pero ya puestos no me puedo quedar aquí, y pienso en crear una imágen que en un futuro pueda usar para desplegar la aplicación en producción, almacenándola en algún registro como **Docker Hub**.

Después de pensar un poco, creo que la opción más limpia es usar **"multi-stage"**.
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


Pero, ya no me puedo quedar quiero, ¿y si trato de desplegar? 👷

## Kubernetes ⚓️

Hace un tiempo, estuve haciendo un curso de Kubernetes y aún mantengo la instalación de **"Minikube"**. Por tanto, es una buena oportunidad de probar.

Empezamos creando un **Deployment** y un **Service** básico en el fichero ``josemlp91-myblog.yml``.

{% highlight yaml %}

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

Y veo que funciona. Subidon de adrenalina. 🎈 🎊 🎉

En este punto ya no me puedo quedar aquí después de darle algunas vueltas,
decido empezar a buscar un cluster **K8S** en la nueve, donde hacer mi experimento, 
lo primero que se me ocurre es tirar de Amazon, Google Cloud o Azure. ☁️ Además alguno de ellos ofrece crédito de forma gratuita para hacer pruebas. Pero creo que hay que darle un puntito más de emoción de la cosa, y tratar de instalar un cluster kubernetes, puede ser un buen reto. 💪 (estoy confinado en casa y tengo tengo todo el puente...).

Comienzo a comparar diferentes proveedores de Servidores Cloud VPS, y consigo encontrar uno que me convence en relación calidad precio. Teniendo en cuenta que necesito tener dos, como mínimo (nodo máster y un worker), y que el master debe tener 2GB de RAM y 2 cores. 

Con mis flamantes máquinas, comienzo a instalar todo, no me extiendo en explicar el proceso, dado que es largo.
Dejo las fuentes que he seguido, al final del post. ⬇️

Y este seria el resultado.

![](/images/nodes.png)


Y ya puedo repetir lo mismo que hacia en minikube, pero esta vez con un cluste de producción.

Para que sea completamente operativo, es esencial crear un ingress, en mi caso me decanto por la implementación
con Nginx, aunque existe muchas otras opciones, ya sea con Traefik o Haproxy. 

En este punto también conozco la herramienta Helm, con la cual implementar el ingress es tan simple como:

{% highlight sh %}
helm install stable/nginx-ingress --name my-nginx --set controller.publishService.enabled=true
{% endhighlight %}

{% highlight yaml %}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: hello-kubernetes-ingress
spec:
  tls:
  - hosts:
    - josemiguelopez.es
    secretName: echo-tls
  rules:
    - host: hellok8s.josemiguelopez.es
      http:
        paths:
          - backend:
              serviceName: hello-kubernetes-first
              servicePort: 80
            path: /
    - host: josemiguelopez.es
      http:
        paths:
        - backend:
            serviceName: josemlp91-myblog
            servicePort: 80
          path: /
{% endhighlight %}

{% highlight sh %}
kubectl create -f first-ingress.yaml
{% endhighlight %}

Con esto solo me queda modificar la entrada de mi dominio, para hacerla apuntar a la Ip pública del nodo máster de mi cluster.

![](/images/pods.png)

## Desplegando 🚀

Probamos que tras actualizar la imagen podemos actualizar el **Deployment** con la nueva versión.
Para que todo sea automático creo un **Makefile**, con la operación "publish", que se ocupa de:

- Construir imágenes
- Subirlas a Docker Hub
- Actualizar el Deployment de K8S. 

{% highlight makefile %}

DOCKER_USERNAME = josemlp91
DOCKER_IMAGE_NAME = myblog
K8S_DEPLOYMENT_NAME = josemlp91-myblog

gitver=$(shell git log -1 --pretty=format:"%H")

publish:  ## Publish image in Docker Hub.
	docker login
	docker build -f Dockerfile.prod -t $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(gitver) .
	docker push $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(gitver)
	docker tag $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(gitver) \
	 $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):latest
	docker push $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):latest
	kubectl set image deployment/$(K8S_DEPLOYMENT_NAME) \ 
	 $(K8S_DEPLOYMENT_NAME)=$(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(gitver)

{% endhighlight %}

## Integración continua ⚙️ ⛓

En este punto, lo interesante sería que todo esto se haga de forma automática al hacer un commit en github, (rama master),
para ello, recurro a TravisCI, que ya esta integrado directamente con GitHub y es gratuito con proyectos de código abierto.

Así queda el archivo ``.travis.yml``, donde lo importante es definir la configuración para conectarte a K8S, mediante variables de entorno secretas.

Otro punto a tener en cuenta, ha sido la instalación de "kubectl" en la máquina de Travis, después de probar varias alternativas,
he podido comprobar que lo más rápido es usar una imágen de docker auxiliar que ya tiene la utilidad "kubectl" instalada. 

{% highlight yaml %}

services:
  - docker

branches:
  only:
  - master

env:
  global:
    - DOCKER_IMAGE_NAME="myblog"
    - K8S_DEPLOYMENT_NAME="josemlp91-myblog"

before_install:
  - docker pull smesch/kubectl
  - docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}"

script:
  - touch kubeconfig
  - docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}" docker.io
  - docker build -f Dockerfile.prod -t ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${TRAVIS_COMMIT} .
  - docker push ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${TRAVIS_COMMIT}
  - docker tag ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${TRAVIS_COMMIT} ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:latest
  - docker push ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:latest
  - sed -i -e 's|KUBE_CA_CERT|'"${KUBE_CA_CERT}"'|g' kubeconfig
  - sed -i -e 's|KUBE_ENDPOINT|'"${KUBE_ENDPOINT}"'|g' kubeconfig
  - sed -i -e 's|KUBE_ADMIN_CERT|'"${KUBE_ADMIN_CERT}"'|g' kubeconfig
  - sed -i -e 's|KUBE_ADMIN_KEY|'"${KUBE_ADMIN_KEY}"'|g' kubeconfig
  - echo "Ready to deploy in K8S."
  - docker run -v ${TRAVIS_BUILD_DIR}:/kube smesch/kubectl kubectl \
    --kubeconfig /kube/kubeconfig set image deployment/${K8S_DEPLOYMENT_NAME} \ 
    ${K8S_DEPLOYMENT_NAME}=${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:$TRAVIS_COMMIT

{% endhighlight %}

## Conclusiones 🔮

Cuando decía antes que "mataba moscas a cañonazos", quería referirme a que no es necesario hacer tal despliegue de tecnologías y componentes, para poner en producción una **web estática**. Además creo que en ciertas situaciones puede ser peligroso puesto que  a la par que automatizando el proceso, incrementamos la complejidad del sistema y la respuesta ante un posible  error sea menos ágil, obligándonos a mirar y rebuscar logs en varios elementos. Siempre hay que pensar en la mejor herramienta a nuestro problema.

Las tecnologías **Devops** y en particular **Docker y Kubernetes** me parece un mundo asombroso, y es por ello que me he tomado este tiempo en hacer este ejercicio y poder contarlo.

Espero poder seguir montando servicios más interesantes e ir escribiendo un poco más a menudo. 


## Referencias 📖

- [Jekyll is a simple, blog-aware, static site generato](https://jekyllrb.com/)
- [The package manager for Kubernetes](https://helm.sh/)
- [Cómo crear un clúster de Kubernetes usando Kubeadm en Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-ubuntu-18-04-es)
- [Cómo configurar un Ingress de Nginx con Cert-Manager en Kubernetes de DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes-es)
- [How To Set Up an Nginx Ingress on DigitalOcean Kubernetes Using Helm](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm)
- [Continuous Deployment with Travis CI and Kubernetes](https://kumorilabs.com/blog/k8s-8-continuous-deployment-travis-ci-kubernetes/)
