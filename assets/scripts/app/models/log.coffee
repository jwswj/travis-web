require 'travis/model'

@Travis.Log = Em.Object.extend
  version: 0 # used to refresh log on requeue
  isLoaded: false
  length: 0

  init: ->
    @_super.apply(@, arguments)
    @clear()
    @fetch(id) if id = @get('job.id')

  fetch: (id) ->
    handlers =
      json: (json) => @loadParts(json['log']['parts'])
      text: (text) => @loadText(text)
    Travis.Log.Request.create(id: id, handlers: handlers).run()

  clear: ->
    @set('parts', Ember.ArrayProxy.create(content: []))
    @incrementProperty('version')

  append: (part) ->
    @get('parts').pushObject(part)

  loadParts: (parts) ->
    @append(part) for part in parts
    @set('isLoaded', true)

  loadText: (text) ->
    @append(number: 0, content: text)
    @set('isLoaded', true)

Travis.Log.Request = Em.Object.extend
  HEADERS:
    accept: 'application/vnd.travis-ci.2+json; chunked=true; version=2, text/plain; version=2'

  run: ->
    Travis.ajax.ajax "/jobs/#{@id}/log?cors_hax=true", 'GET',
      dataType: 'text'
      headers: @HEADERS
      success: (body, status, xhr) => @handle(body, status, xhr)

  handle: (body, status, xhr) ->
    if xhr.status == 204
      $.ajax(url: redirectTo(xhr), type: 'GET', success: @handlers.text)
    else if @isJson(xhr, body)
      @handlers.json(JSON.parse(body))
    else
      @handlers.text(body)

  redirectTo: (xhr) ->
    # Firefox can't see the Location header on the xhr response due to the wrong
    # status code 204. Should be some redirect code but that doesn't work with CORS.
    xhr.getResponseHeader('Location') || @s3Url()

  s3Url: ->
    endpoint = Travis.config.api_endpoint
    staging = if endpoint.match(/-staging/) then '-staging' else ''
    host = endpoint.replace(/^https?:\/\//, '').split('.').slice(-2).join('.')
    "https://s3.amazonaws.com/archive#{staging}.#{host}#{path}/jobs/#{@id}/log.txt"

  isJson: (xhr, body) ->
    # Firefox can't see the Content-Type header on the xhr response due to the wrong
    # status code 204. Should be some redirect code but that doesn't work with CORS.
    type = xhr.getResponseHeader('Content-Type') || ''
    type.indexOf('json') > -1 || body.slice(0, 8) == '{"log":{'
