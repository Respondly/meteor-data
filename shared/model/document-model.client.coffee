#= require ./document-model

###
Retrieves the scoped session for the model.
This can be used client-side for storing view state information.
###
Data.DocumentModel::session = ->
  return if @isDisposed
  @__internal__.session = Data.DocumentModel.session(@) unless @__internal__._session?
  @__internal__.session
