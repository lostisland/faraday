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
* [`Multipart`][multipart] converts a `Faraday::Request#body` hash of key/value pairs into a
multipart form request.
* [`UrlEncoded`][url_encoded] converts a `Faraday::Request#body` hash of key/value pairs into a url-encoded request body.
* [`Retry`][retry] automatically retries requests that fail due to intermittent client
or server errors (such as network hiccups).
* [`Instrumentation`][instrumentation] allows to instrument requests using different tools.


### Response Middleware

**Response middleware** receives the response from the adapter and can modify its details
before returning it.

* [`Logger`][logger] logs both the request and the response body and headers.
* [`RaiseError`][raise_error] checks the response HTTP code and raises an exception if it is a 4xx or 5xx code.


[authentication]:       ./authentication
[multipart]:            ./multipart
[url_encoded]:          ./url-encoded
[retry]:                ./retry
[instrumentation]:      ./instrumentation
[logger]:               ./logger
[raise_error]:          ./raise-error
