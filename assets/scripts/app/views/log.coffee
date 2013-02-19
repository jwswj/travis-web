require 'log'

@Travis.reopen
  LogView: Travis.View.extend
    templateName: 'jobs/log'

    logSubscriber: (->
      job.subscribe() if (job = @get('job')) && !job.get('isFinished')
    ).observes('job', 'job.state')

    plainTextLogUrl: (->
      Travis.Urls.plainTextLog(id) if id = @get('job.log.id')
    ).property('job.log.id')

    toTop: () ->
      $(window).scrollTop(0)

  LogPreView: Em.View.extend
    templateName: 'jobs/pre'

    init: ->
      @_super.apply(this, arguments)
      @scroll = new Log.Scroll
      @engine = @createLog()

    rerender: ->
      @_super.apply(this, arguments)
      @engine = @createLog()

    createLog: ->
      Log.create(listeners: [new Log.FragmentRenderer, new Log.Folds, @scroll])

    didInsertElement: ->
      @_super.apply(this, arguments)
      parts = @get('log.parts')
      parts.addArrayObserver(@, didChange: 'partsAdded', willChange: ->)
      @partsAdded(parts.slice(0))
      @lineNumbers()
      @scroll.set(@get('controller.lineNumber'))
      @folds()

    willDestroy: ->
      @get('log.parts').removeArrayObserver(@, didChange: 'partsAdded', willChange: ->)

    versionObserver: (->
      @rerender()
    ).observes('log.version')

    lineNumberObserver: (->
      @scroll.set(number) if !@get('isDestroyed') && number = @get('controller.lineNumber')
    ).observes('controller.lineNumber')

    partsAdded: (parts, start, _, added) ->
      start ||= 0
      added ||= parts.length
      @engine.set(part.number, part.content) for part, i in parts.slice(start, start + added)

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


