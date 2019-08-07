---
layout: post
title:  "Django StarUML extension"
description: "StarUML extension to auto generate Django Models."
date:   2018-11-19 19:19:43
keywords: "uml, staruml, django, developer, software"
comments: false
category: django
image: /images/staruml.png
summary: StarUML extension to auto auto-generate Django Models, some prominent feature are auto-generate model class, attributes, inheritance, relationship and aditional params.
---


## Features

- Auto-generate **Django Model Class**.
- Auto-generate attributes with the suitable **type**, using standard ``Djando Model Field``, provided by Django ORM.
- Generate **inheritance**, (if not exist by default ``models.Model``).
- Generate **relationship**, using **cardinality**, create suitable fields,  ``OneToOne``, ``ForeingKey`` and ``ManyToMany``.
- Auto add attributes in **Meta** models, using ``tags``.
- Auto add aditional **params** to model attributes and model relationships fields using defined ``tags``.


## Requirements

To run auto-generate field with suitable ``Django Mode Field``, is necesary to 
have a diagram with a class for each basic type loaded.

You could download this scheme with [basic class types](https://raw.githubusercontent.com/josemlp91/staruml-django/master/assets/basictypes.mdj)

### Basic Types

- **string**:  ``models.CharField``
- **text**:  ``models.TextField``
- **integer**:   ``models.IntegerField``
- **decimal**:  ``models.DecimalField``
- **boolean**:   ``models.BooleanField``
- **date**:   ``models.DateField``
- **datetime**:   ``models.DateTimeField``
- **email**:  ``models.EmailField``
- **file**:  ``models.FileField``

![](https://raw.githubusercontent.com/josemlp91/staruml-django/master/docs/images/basic_types.png)


## Installation

1. Install **StarUML**,  [download page](http://staruml.io/download).
2. Download or clone this [repo](https://github.com/josemlp91/staruml-django).
3. Copy repo files to StarUML extension user folder.
	- **MacOS:** `~/Library/Application Support/StarUML/extensions/user/staruml-django`
	- **Windows:** `C:\Users\<user>\AppData\Roaming\StarUML\extensions\user\staruml-django`
	- **Linux:** `~/.config/StarUML/extensions/user/staruml-django`

## Usage

1. Click the menu (`Tools > Django Models > Generate Code...`)
2. Select a base model (or package) that will be generated to Django Models.
3. Select a folder where generated Python source files (.py) will be placed.

## Sample

![](https://raw.githubusercontent.com/josemlp91/staruml-django/master/docs/images/example_diagram.png)


### AbstactStudent Model
{% highlight python %}

#-*- coding: utf-8 -*-

from django.db import models

class AbstractStudent(models.Model):
    class Meta:
        verbose_name='foo'

    type = models.CharField()
{% endhighlight %}

### Student Model
{% highlight python %}
#-*- coding: utf-8 -*-

from django.db import models
from AbstractStudent import AbstractStudent

class Student(AbstractStudent):
    class Meta:
        verbose_name='student'

    name = models.CharField(max_length=1024, verbose_name='name', null=True)
    surname = models.CharField()
    birthdate = models.DateField()

    school = models.ForeingKey('School', on_delete=models.PROTECT)
    teachers = models.ManyToMany('Teacher')
    expedient = models.OneToOne('Expedient')

    @property
    def age(self, ):
        pass
{% endhighlight %}

### Teacher Model

{% highlight python %}
#-*- coding: utf-8 -*-

from django.db import models

class Teacher(models.Model):
    class Meta:
        pass

    name = models.CharField()
    speciality = models.CharField()

    school = models.ForeingKey('School', related_name='teachers', on_delete=models.PROTECT)

{% endhighlight %}

### School Model


{% highlight python %}
#-*- coding: utf-8 -*-

from django.db import models

class School(models.Model):
    class Meta:
        pass

    name = models.CharField()
    address = models.CharField()
{% endhighlight %}


## Disclainer
This project is now in **beta**, not ready for production or profesional use.
Use and modify by your own responsability.

## Contributors

- José Miguel López Pérez [josmilope@gmail.com](josmilope@gmail.com)
- Based on [https://github.com/niklauslee/staruml-python](https://github.com/niklauslee/staruml-python)


[Spanish Translation](https://github.com/josemlp91/staruml-django/blob/master/README_es.md) 