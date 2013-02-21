require 'log'

@Travis.reopen
  LogView: Travis.View.extend
    templateName: 'jobs/log'

    logSubscriber: (->
      job.subscribe() if (job = @get('job')) && !job.get('isFinished')
    ).observes('job', 'job.state')

    toTop: () ->
      $(window).scrollTop(0)

    didInsertElement: ->
      @get('job.log').fetch()


  LogPreView: Em.View.extend
    templateName: 'jobs/pre'
    logBinding: 'job.log'

    init: ->
      @_super.apply(this, arguments)

    rerender: ->
      @_super.apply(this, arguments)
      @createEngine()

    didInsertElement: ->
      @createEngine()
      @observeParts()
      @lineNumbers()
      @scroll.set(@get('controller.lineNumber'))
      @folds()

    createEngine: ->
      @scroll = new Log.Scroll
      @limit  = new Log.Limit
      @propertyDidChange('isLimited')
      @engine = Log.create(listeners: [@limit, new Log.FragmentRenderer, new Log.Folds, @scroll])

    observeParts: ->
      parts = @get('log.parts')
      parts.addArrayObserver(@, didChange: 'partsAdded', willChange: ->)
      @partsAdded(parts.slice(0))

    willDestroy: ->
      if parts = @get('log.parts')
        parts.removeArrayObserver(@, didChange: 'partsAdded', willChange: ->)
      else
        console.log('can not remove observer from parts because parts is undefined')

    versionObserver: (->
      @rerender()
    ).observes('log.version')

    lineNumberObserver: (->
      @scroll.set(number) if !@get('isDestroyed') && number = @get('controller.lineNumber')
    ).observes('controller.lineNumber')

    partsAdded: (parts, start, _, added) ->
      unless @get('isLimited')
        start ||= 0
        added ||= parts.length
        @engine.set(part.number, part.content) for part, i in parts.slice(start, start + added)
        @propertyDidChange('isLimited')

    isLimited: (->
      @limit && @limit.isLimited()
    ).property()

    plainTextLogUrl: (->
      Travis.Urls.plainTextLog(id) if id = @get('log.job.id')
    ).property('job.log.id')

    toggleTailing: (event) ->
      Travis.app.tailing.toggle()
      event.preventDefault()

    lineNumbers: ->
      $('#log').on 'mouseenter', 'a', ->
        $(this).attr('href', '#L' + ($(this.parentNode).prevAll('p').length + 1))

    folds: ->
      $('#log').on 'click', '.fold', ->
        $(this).toggleClass('open')

    click: (event) ->
      target = $(event.target)
      target.closest('.fold').toggleClass('open')
      if target.is('a') && matches = target.attr('href')?.match(/#L(\d+)$/)
        Travis.app.get('router.location').setURL(target.attr('href'))
        @set('controller.lineNumber', matches[1])
        event.stopPropagation()
        return false

Log.Scroll = ->
Log.Scroll.prototype = $.extend new Log.Listener,
  set: (number) ->
    return unless number
    @number = number
    @tryScroll()

  insert: (log, after, data) ->
    @tryScroll() if @number

  tryScroll: ->
    if element = $("#log p:nth-child(#{@number})")
      $('#main').scrollTop(0)
      $('html, body').scrollTop(element.offset()?.top) # weird, html works in chrome, body in firefox
      @highlight(element)
      @number = undefined

  highlight: (element) ->
    $('#log p.highlight').removeClass('highlight')
    $(element).addClass('highlight')

Log.Limit = ->
Log.Limit.prototype = $.extend new Log.Listener,
  MAX_LINES: 5000
  count: 0

  insert: (log, after, lines) ->
    @count += lines.length
    lines.length = @MAX_LINES if lines.length > @MAX_LINES

  isLimited: ->
    @count > @MAX_LINES


