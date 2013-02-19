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
    Travis.ajax.ajax "/jobs/#{jobId}/log.txt?cors_hax=true", 'GET',
      dataType: 'text'
      contentType: 'text/plain'
      success: (body, status, xhr) =>
        if xhr.status == 204
          # Firefox can't see the Location header on the xhr response, probably due to
          # the wrong (?) status code 204. Should be some redirect code but that doesn't
          # seem to work with CORS.
          url = xhr.getResponseHeader('Location') || @s3Url(jobId)
          $.ajax(url: url, type: 'GET', success: (body) => @setBody(body))
        else
          @setBody(body)

  setBody: (body) ->
    @get('parts').pushObject(body)
    @set('isLoaded', true)

  s3Url: (id) ->
    endpoint = Travis.config.api_endpoint
    staging = if endpoint.match(/-staging/) then '-staging' else ''
    host = Travis.config.api_endpoint.replace(/^https?:\/\//, '').split('.').slice(-2).join('.')
    "https://s3.amazonaws.com/archive#{staging}.#{host}#{path}/jobs/#{jobId}/log.txt"
