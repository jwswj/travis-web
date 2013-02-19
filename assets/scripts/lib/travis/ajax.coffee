jQuery.support.cors = true

@Travis.ajax = Em.Object.create
  DEFAULT_OPTIONS:
    accepts:
      json: 'application/vnd.travis-ci.2+json'

  get: (url, callback) ->
    @ajax(url, 'get', success: callback)

  post: (url, data, callback) ->
    @ajax(url, 'post', data: data, success: callback)

  ajax: (url, method, options) ->
    method = method.toUpperCase()
    endpoint = Travis.config.api_endpoint || ''
    options = options || {}

    if token = Travis.sessionStorage.getItem('travis.token')
      options.headers ||= {}
      options.headers['Authorization'] ||= "token #{token}"

    options.url = "#{endpoint}#{url}"
    options.type = method
    options.dataType = options.dataType || 'json'
    options.context = this

    if options.data && method != 'GET'
      options.data = JSON.stringify(options.data)

    if method != 'GET' && method != 'HEAD'
      options.contentType ||= 'application/json; charset=utf-8'

    success = options.success || (->)
    options.success = (data) =>
      Travis.app.router.flashController.loadFlashes(data.flash) if Travis.app?.router && data.flash
      delete data.flash
      success.apply(this, arguments)

    error = options.error || (->)
    options.error = (data) =>
      Travis.app.router.flashController.pushObject(data.flash) if data.flash
      delete data.flash
      error.apply(this, arguments)

    $.ajax($.extend(Travis.ajax.DEFAULT_OPTIONS, options))
