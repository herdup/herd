Herd.AssetContainerComponent = Ember.Component.extend
  action: 'generateChild'
  classNames: ['asset-container']
  bgImage: true
  asset: null
  child: null
  transform: null
  t: null
  n: null

  +computed asset, child
  isImage: ->
    return @asset?.type == 'Herd::Image' unless @child
    @child.type == 'Herd::Image' and !@bgImage

  +computed child
  isVideo: ->
    return @asset?.type == 'Herd::Video' unless @child
    @child.type == 'Herd::Video'

  +computed asset, transform, child.url, child.updatedAt
  assetUrl: ->
    if @child
      if Ember.empty @child.fileName
        return "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
      else
        return "#{@child?.url}?b=#{@child.updatedAt.getTime()}"

    else if @asset and (@t or @n)
      @child = @asset if @asset.assetableId == 0
      @child = @asset.n @n if !@child and @n
      @child = @asset.t @t unless @child

      if @child?.url
        return @assetUrl
      else
        Ember.run =>
          # this needs to be refactored into a controller, maybe using @sendAction
          @child = @asset.store.createRecord 'asset',
            parentAsset: @asset
            transform: @transform || @asset.store.createRecord 'transform',
              name: @n
              options: @t
              assetableType: @asset.assetableType

          @child.save()

      "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
    else if @asset
      @asset.url
    else
      "http://www.york.ac.uk/media/environment/images/staff/NoImageAvailableFemale.jpg"

  actions:
    metaUpdate: ->
      @asset.save()
