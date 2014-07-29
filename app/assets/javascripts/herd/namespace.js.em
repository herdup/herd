#= require jquery
#= require jquery.ui.sortable
#= require handlebars
#= require ember
#= require ember-data
#= require ember-uploader
#= require js-yaml

#= require_self

#= require_tree ./models
#= require_tree ./mixins
#= require_tree ./views
#= require_tree ./components
#= require_tree ./templates


window.Herd = Ember.Namespace.create
  VERSION: '1.0.0'
