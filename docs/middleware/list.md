---
layout: documentation
title: "Available Middleware"
permalink: /middleware/list
hide: true
top_name: Middleware
top_link: ./
next_name: Writing Middleware
next_link: ./custom
---

Faraday ships with some useful middleware that you can use to customize your request/response lifecycle.
Middleware are separated into two macro-categories: **Request Middleware** and **Response Middleware**.
The former usually deal with the request, encoding the parameters or setting headers.
The latter instead activate after the request is completed and a response has been received, like
parsing the response body, logging useful info or checking the response status.

### Request Middleware

**Request middleware** can modify Request details before the Adapter runs. Most
middleware set Header values or transform the request body based on the
content type.

* [`BasicAuthentication`][authentication] sets the `Authorization` header to the `user:password`
base64 representation.
* [`TokenAuthentication`][authentication] sets the `Authorization` header to the specified token.
* [`UrlEncoded`][url_encoded] converts a `Faraday::Request#body` hash of key/value pairs into a url-encoded request body.
* [`Json Request`][json-request] converts a `Faraday::Request#body` hash of key/value pairs into a JSON request body.
* [`Instrumentation`][instrumentation] allows to instrument requests using different tools.


### Response Middleware

**Response middleware** receives the response from the adapter and can modify its details
before returning it.

* [`Json Response`][json-response] parses response body into a hash of key/value pairs.
* [`Logger`][logger] logs both the request and the response body and headers.
* [`RaiseError`][raise_error] checks the response HTTP code and raises an exception if it is a 4xx or 5xx code.


[authentication]:       ./authentication
[url_encoded]:          ./url-encoded
[json-request]:         ./json-request
[instrumentation]:      ./instrumentation
[json-response]:        ./json-response
[logger]:               ./logger
[raise_error]:          ./raise-error
