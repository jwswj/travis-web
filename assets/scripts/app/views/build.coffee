@Travis.reopen
  BuildsView: Travis.View.extend
    templateName: 'builds/list'
    buildsBinding: 'controller.builds'

    isPullRequestsList: (->
      @get('controller.tab') == 'pull_requests'
    ).property('controller.tab')

    showMore: ->
      id     = @get('controller.repo.id')
      number = @get('builds.lastObject.number')
      @get('builds').load Travis.Build.olderThanNumber(id, number)

    ShowMoreButton: Em.View.extend
      tagName: 'button'
      classNameBindings: ['isLoading']
      attributeBindings: ['disabled']
      isLoadingBinding: 'controller.builds.isLoading'
      template: Em.Handlebars.compile('{{view.label}}')

      disabledBinding: 'isLoading'

      label: (->
        if @get('isLoading') then 'Loading' else 'Show more'
      ).property('isLoading')

      click: ->
        @get('parentView').showMore()

  BuildsItemView: Travis.View.extend
    tagName: 'tr'
    classNameBindings: ['color']
    repoBinding: 'controller.repo'
    buildBinding: 'context'
    commitBinding: 'build.commit'

    color: (->
      Travis.Helpers.colorForState(@get('build.state'))
    ).property('build.state')

    urlGithubCommit: (->
      Travis.Urls.githubCommit(@get('repo.slug'), @get('commit.sha'))
    ).property('repo.slug', 'commit.sha')

    urlGithubPullRequest: (->
      Travis.Urls.githubPullRequest(@get('repo.slug'), @get('commit.pullRequestNumber'))
    ).property('repo.slug', 'commit.pullRequestNumber')

  BuildView: Travis.View.extend
    templateName: 'builds/show'
    elementId: 'build'
    classNameBindings: ['color', 'loading']

    repoBinding: 'controller.repo'
    buildBinding: 'controller.build'
    commitBinding: 'build.commit'

    currentItemBinding: 'build'

    loading: (->
      !@get('build.isLoaded')
    ).property('build.isLoaded')

    color: (->
      Travis.Helpers.colorForState(@get('build.state'))
    ).property('build.state')

    urlGithubCommit: (->
      Travis.Urls.githubCommit(@get('repo.slug'), @get('commit.sha'))
    ).property('repo.slug', 'commit.sha')

    urlAuthor: (->
      Travis.Urls.email(@get('commit.authorEmail'))
    ).property('commit.authorEmail')

    urlCommitter: (->
      Travis.Urls.email(@get('commit.committerEmail'))
    ).property('commit.committerEmail')

