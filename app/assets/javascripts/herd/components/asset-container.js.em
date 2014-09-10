Herd.AssetContainerComponent = Ember.Component.extend
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

  +computed options
  optionsHash: ->
    return unless @t
    yaml = @t.split('|').join("\n")
    hash = jsyaml.load yaml
    sorted = {}
    for k in Object.keys(hash).sort()
      sorted[k] = hash[k]

    sorted

  +computed options
  sortedOptionsSegment: ->
    yaml = jsyaml.dump @optionsHash
    encodeURIComponent yaml.split("\n").join('|')

  +computed asset, transform, child.url, child.updatedAt
  assetUrl: ->
    @child = @asset if @asset.assetableId == 0

    if @child and @child.url
      return "#{@child?.url}?#{@child.updatedAt.getTime()}"

    else if @asset and (@t or @n)
      @child = @asset.n @n if @n
      @child = @asset.t @t unless @child

      if @child?.url
        return "#{@child?.url}?#{@child.updatedAt.getTime()}"
      else
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
