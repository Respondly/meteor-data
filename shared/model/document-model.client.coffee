#= require ./document-model

###
Retrieves the scoped session for the model.
This can be used client-side for storing view state information.
###
Data.DocumentModel::session = ->
  return if @isDisposed
  @__internal__.session = Data.DocumentModel.session(@) unless @__internal__._session?
  @__internal__.session



###
Gets the scoped-session singleton for the given model instance.
@param instance:  The [DocumentModel] instance to retrieve the
                  session for.
###
Data.DocumentModel.session = (instance) ->
  return unless instance?.id?
  ScopedSession.singleton("#{ Data.Model.typeName(instance) }:#{instance.id}")
