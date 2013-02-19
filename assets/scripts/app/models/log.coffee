require 'travis/model'

@Travis.Log = Em.Object.extend
  version: 0 # used to refresh log on requeue
  isLoaded: false

  init: ->
    @_super.apply(@, arguments)
    @clear()
    @fetch(jobId) if jobId = @get('job.id')

  append: (part) ->
    @get('parts').pushObject(part)

  clear: ->
    @set('parts', Ember.ArrayProxy.create(content: []))
    @incrementProperty('version')

  fetch: (jobId) ->
    Travis.ajax.ajax "/jobs/#{jobId}/log?cors_hax=true", 'GET',
      dataType: 'text'
      headers:
        accept: 'application/vnd.travis-ci.2+json; chunked=true; version=2, text/plain; version=2'
      success: (body, status, xhr) =>
        if xhr.status == 204
          $.ajax(url: redirectTo(xhr, jobId), type: 'GET', success: (body) => @loadText(body))
        else if @isJson(xhr, body)
          @loadParts(JSON.parse(body)['log']['parts'])
        else
          @loadText(body)

  loadParts: (parts) ->
    @append(part) for part in parts
    @set('isLoaded', true)

  loadText: (text) ->
    @get('parts').pushObject(number: 0, content: text)
    @set('isLoaded', true)

  redirectTo: (xhr, id) ->
    # Firefox can't see the Location header on the xhr response due to the
    # wrong status code 204. Should be some redirect code but that doesn't
    # seem to work with CORS.
    xhr.getResponseHeader('Location') || @s3Url(id)

  s3Url: (id) ->
    endpoint = Travis.config.api_endpoint
    staging = if endpoint.match(/-staging/) then '-staging' else ''
    host = endpoint.replace(/^https?:\/\//, '').split('.').slice(-2).join('.')
    "https://s3.amazonaws.com/archive#{staging}.#{host}#{path}/jobs/#{jobId}/log.txt"

  isJson: (xhr, body) ->
    # Firefox can't see the Content-Type header on the xhr response due to the
    # wrong status code 204. Should be some redirect code but that doesn't
    # seem to work with CORS.
    type = xhr.getResponseHeader('Content-Type') || ''
    type.indexOf('json') > -1 || body.slice(0, 8) == '{"log":{'
