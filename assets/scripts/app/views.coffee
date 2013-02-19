require 'ext/ember/namespace'

@Travis.reopen
  View: Em.View.extend
    popup: (event) ->
      @popupCloseAll()
      name = if event.target then event.target.name else event
      $("##{name}").toggleClass('display')
    popupClose: (event) ->
      $(event.target).closest('.popup').removeClass('display')
    popupCloseAll: ->
      if view = Travis.View.currentPopupView
        view.destroy()
        Travis.View.currentPopupView = null

      $('.popup').removeClass('display')

require 'views/accounts'
require 'views/application'
require 'views/build'
require 'views/events'
require 'views/flash'
require 'views/job'
require 'views/log'
require 'views/repo'
require 'views/profile'
require 'views/sidebar'
require 'views/stats'
require 'views/signin'
require 'views/top'
require 'views/status_images'
