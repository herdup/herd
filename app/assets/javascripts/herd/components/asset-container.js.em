Herd.AssetContainerComponent = Ember.Component.extend
  action: 'generateChild'
  classNames: ['asset-container']
  bgImage: true
  asset: null
  child: null
  transform: null
  t: null
  n: null
  suffix: null


  combinedName: ~>
    if @suffix
      [@n,@suffix].join '-'
    else
      @n

  isImage: ~>
    return @asset?.type == 'Herd::Image' unless @child
    @child.type == 'Herd::Image' and !@bgImage


  isVideo: ~>
    return @asset?.type == 'Herd::Video' unless @child
    @child.type == 'Herd::Video'


  assetUrl: ~>
    if @child
      if Ember.empty @child.fileName
        return "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
      else
        return "#{@child?.url}?b=#{@child.updatedAt.getTime()}"

    else if @asset and (@t or @combinedName)
      @child = @asset if @asset.assetableId == 0
      @child = @asset.n @combinedName if !@child and @combinedName
      @child = @asset.t @t unless @child

      if @child?.url
        return @assetUrl
      else
        Ember.run =>
          # this needs to be refactored into a controller, maybe using @sendAction
          @child = @asset.store.createRecord 'asset',
            parentAsset: @asset
            transform: @transform || @asset.store.createRecord 'transform',
              name: @combinedName
              options: @t
              assetableType: @asset.assetableType

          @child.save()

      "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
    else if @asset
      @asset.url
    else
      null

  actions:
    metaUpdate: ->
      @asset.save()
