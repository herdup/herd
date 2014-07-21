# For more information see: http://emberjs.com/guides/routing/

Herd.Router.map ->
  @resource 'assets',{path: '/'}, ->
    @route 'show', {path: '/:id'}
    
  @resource 'transforms', ->
    @route 'show', {path: '/:id'}
    @route 'new'
