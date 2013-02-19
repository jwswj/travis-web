I18nBoundView = Ember.View.extend Ember._Metamorph,
  key: null,

  init: ->
    @_super()
    Travis.addObserver('locale', @, 'valueDidChange')

  valueForRender: ->
    new Handlebars.SafeString I18n.t(@key)

  valueDidChange: ->
    @morph.html(@valueForRender()) unless @morph.isRemoved()

  didInsertElement: ->
    @valueDidChange()

  destroy: ->
    Travis.removeObserver('locale', @, 'valueDidChange')
    @_super()

  render: (buffer) ->
    buffer.push(@valueForRender())


Ember.Handlebars.registerHelper 't', (key, options) ->
  view = options.data.view
  bindView = view.createChildView(I18nBoundView, { key: key })
  view.appendChild(bindView)
  # dont write any content from @helper, let the child view
  # take care of itself.
  false

