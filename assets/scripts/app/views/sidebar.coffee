@Travis.reopen
  SidebarView: Travis.View.extend
    templateName: 'layouts/sidebar'

    DecksView: Em.View.extend
      templateName: "sponsors/decks"
      init: ->
        @_super.apply this, arguments
        @set 'controller', @get('controller').container.lookup('controller:decks')

    LinksView: Em.View.extend
      templateName: "sponsors/links"
      init: ->
        @_super.apply this, arguments
        @set 'controller', @get('controller').container.lookup('controller:links')

    WorkersView: Em.View.extend
      templateName: 'workers/list'
      init: ->
        @_super.apply this, arguments
        @set 'controller', @get('controller').container.lookup('controller:workers')

    QueuesView: Em.View.extend
      templateName: 'queues/list'
      init: ->
        @_super.apply this, arguments
        @set 'controller', @get('controller').container.lookup('controller:queues')

    RunningJobsView: Em.View.extend
      templateName: 'jobs/running'
      elementId: 'running-jobs'
      init: ->
        @_super.apply this, arguments
        @set 'controller', @get('controller').container.lookup('controller:runningJobs')

      groupsBinding: 'controller.sortedGroups'
      jobsBinding: 'controller'

      GroupView: Em.View.extend
        templateName: 'jobs/running/group'
        tagName: 'li'
        contextBinding: 'group'
        expanded: false
        classNameBindings: ['expanded']
        classNames: ['group']
        toggle: ->
          @toggleProperty('expanded')


  WorkersView: Travis.View.extend
    toggleWorkers: ->
      handle = $(event.target).toggleClass('open')
      if handle.hasClass('open')
        $('#workers li').addClass('open')
      else
        $('#workers li').removeClass('open')

  WorkersListView: Travis.View.extend
    toggle: ->
      this.$().find('> li').toggleClass('open')

  WorkersItemView: Travis.View.extend
    classNameBindings: ['worker.state']

    display: (->
      name = (@get('worker.name') || '').replace('travis-', '')
      state = @get('worker.state')

      if state == 'working'
        "<span class='name'>#{name}: #{@get('worker.repoSlug')}</span> ##{@get('worker.jobNumber')}".htmlSafe()
      else
        "#{name}: #{state}"
    ).property('worker.state')

  QueueItemView: Travis.View.extend
    tagName: 'li'
