###
The base class for models that are sub-documents.
###
class Data.SubModel extends Data.Model
  ###
  Constructor.
  @param doc:        The document instance being wrapped.
  @param schema:     The schema Type (or an instance) that defines the model's properties.
  ###
  constructor: (doc, schema) ->
    super doc, schema


  ###
  Updates the field within the parent [DocumentModel].
  ###
  update: ->
    @parentModel.updateFields(@parentField)



