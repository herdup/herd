class Herd.AssetsIndexView extends Ember.View
  didInsertElement: ->
    controller = @controller

    $(".sortable").sortable
      update: (e, ui) ->
        $view = $(@)
        indexes = {}

        $view.find('.item').each (ix) ->
          indexes[$(@).data('id')] = ix

        $view.sortable 'cancel'

        controller.updateSortOrder indexes
