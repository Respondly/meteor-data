#= require ./model
Model = Data.Model



###
TODO

- strip out fnFunc into it's own file.

- TEST: db updates for sub-models.

- remove other _fields

###


observers = {}
observeCollection = (collection) ->
  name = collection._name
  return if observers[name]

  cursor = collection.find({})
  cursor.observeChanges
    changed: (id, fields) ->
        if instances = Data.DocumentModel.instances[id]
          for fieldName, value of fields
            for instanceId, model of instances
              # Only update the model if it has been set as reactive.
              if model.db.isReactive
                model[fieldName]?(value)

    removed: (id) ->
        if instances = Data.DocumentModel.instances[id]
            for instanceId, model of instances
              model.dispose()



storeReference = (model) ->
  if id = model.id
    Data.DocumentModel.instances[id] ?= {}
    Data.DocumentModel.instances[id][model.__internal__.instance] = model


# ----------------------------------------------------------------------


###
Base class for models that represent Mongo documents.

This provides a way of wrapping model logic around
a document instance.
###
Data.DocumentModel = class DocumentModel extends Model
  ###
  Constructor.
  @param doc:        The document instance being wrapped.
  @param schema:     The schema Type (or an instance) that defines the model's properties.
  @param collection: The Mongo collection the document resides within.
  ###
  constructor: (doc, schema, collection) ->
    super doc, schema
    @id = @_doc._id
    storeReference(@)
    @db.collection = collection
    observeCollection(collection)



  ###
  Disposes of the object.
  ###
  dispose: ->
    super
    @__internal__.session?.dispose()
    delete DocumentModel.instances[@id][@__internal__.instance]
    delete DocumentModel.instances[@id] if Object.isEmpty(DocumentModel.instances[@id])




  ###
  The default selector to use for updates and deletes
  ###
  defaultSelector: -> @id


  ###
  Assumes an unsaved document has been created.
  Inserts the document, and inserts the db into the document
  @param options:
              - id: (optional) The ID string to use.  If omitted a default ID is generated.
                               NB:  This is useful if wishing to specify a shorter ID which
                                    may be desirable if the ID shows up in a URL.
  ###
  insertNew: (options = {}) ->
    # Setup initial conditions.
    throw new Error('Already exists.') if @id?

    # Ensure all default values from the schema are on the document.
    @setDefaultValues()
    doc = @_doc

    # Use the given ID if one was specified.
    if id = options.id
      doc._id = id

    # Insert into collection.
    newId = @db.collection.insert(doc)
    doc._id = newId
    @id = newId
    storeReference(@)

    # Finish up.
    @__internal__.changeStore?.clear?()
    @


  ###
  OVERRIDE: Merges into the models document default values from the
  schema for values that are not already present.
  ###
  setDefaultValues: ->
    # Setup initial conditions.
    result = super
    changes = @changes()
    now = +(new Date())

    # Set the 'createdAt' timestamp if required.
    if Object.isFunction(@createdAt)
      unless @createdAt()?
        @createdAt(now)

    # Set the 'createdAt' timestamp if required.
    if Object.isFunction(@updatedAt)
      unless @updatedAt()?
        @updatedAt(now)

    # Run the [beforeSave] filter.
    for key, value of changes
      field = @[key].definition
      value = beforeSaveFilter(@, field, value)

    # Finish up.
    result



  ###
  Updates the document in the DB.
  @param updates:   The change instructions, eg $set:{ foo:123 }
  @param options:   Optional Mongo update options.
  ###
  update: (updates, options) ->
    @db.collection.update(@defaultSelector(), updates, options)


  ###
  Updates the specified fields in the DB.
  @param fields:  The schema definitions of the fields to save.
  ###
  updateFields: (fields...) ->
    # Setup initial conditions.
    fields = fields.flatten()
    fields = fields.map (f) ->
                if Object.isFunction(f) then f.definition else f
    fields = fields.flatten()

    # Invoke the "before" handlers.
    _beforeUpdateFields.each (func) => func(@, fields)

    # Set the 'updatedAt' timestamp if required.
    do =>
      updatedAt = @db.fields.updatedAt
      if updatedAt?.type?.name is 'Date'
        alreadyExists = fields.find (item) -> item.key is updatedAt.key
        unless alreadyExists
          @updatedAt +(new Date())
          fields.add( updatedAt )

    # Build the change-set.
    change = {}
    for field in fields
      prop = @[field.key]
      if field.modelRef?
        # A referenced model. Pass the sub-document to be saved.
        value = prop._doc
      else
        # A property-func, read the value.
        value = prop.apply(@)
        value = +(value) if Object.isDate(value)

      # Run the [beforeSave] filter.
      value = beforeSaveFilter(@, field, value)

      # Store the value on the change-set
      change[field.field] = value

      # Remove from the model's "is-dirty" changes object.
      @changes(key:field.key, value:undefined)

    # Save.
    @update $set:change


  ###
  Deletes and disposes of the model.
  ###
  delete: ->
    @db.collection.remove(@defaultSelector())
    @dispose()


  ###
  Re-queries the document from the collection.
  ###
  refresh: ->
    collection = @db.collection
    return unless collection? and @db.schema?
    doc = collection.findOne(@id)
    @__internal__.init(doc) if doc?
    @


  ###
  Updates a model from the given change-set.
  @param changes: The change-set (see the [changes] method).
  @param options:
            - save: Flag indicating if changes should be updated in the DB (default:false)
  @returns an array of changed field definitions.
  ###
  syncChanges: (changes = {}, options = {}) ->
    fields = super(changes)
    @updateFields(fields) if fields.length > 0 and options.save is true
    fields


  ###
  Saves the model's current change-set to the DB.
  ###
  saveChanges: -> @syncChanges(@changes(), save:true)


  ###
  OVERRIDE
  ###
  changes: (options = {}) ->
    # Persist changes between hot-code pushes on the client.
    if Meteor.isClient and @id?
      @__internal__.changeStore = @session()
    super



# PRIVATE --------------------------------------------------------------------------



beforeSaveFilter = (model, field, value) ->
  # Setup initial conditions.
  return unless field
  fnFilter = model[field.key].beforeSave
  return value unless Object.isFunction(fnFilter)

  # Run the filter.
  result = fnFilter(value)

  # Update the model if there was a change.
  model[field.key](result) if result isnt value

  # Finish up.
  result


# CLASS PROPERTIES / METHODS -------------------------------------------------------------------


DocumentModel.isDocumentModelType = true # Flag used to identify the type.
Data.DocumentModel.instances = {}




###
Retrieves a singleton instance of a model.
@param id:        The model ID or the model Type

@param fnFactory: Factory for creating the model if it does not yet exist:
                    - func(id)
                    - ModelType(doc)

###
DocumentModel.singleton = (id, fnFactory) ->
  # Setup initial conditions.
  return unless id?
  doc = id if id._id
  id  = doc._id if doc?
  instances = DocumentModel.instances[id]

  # Create the model if one does not already exist.
  if not instances? or Object.isEmpty(instances)
    if fnFactory?.isDocumentModelType and doc?
      # Create from Type.
      new fnFactory(doc)

    else if Object.isFunction(fnFactory)
      # Create from factory function.
      fnFactory?(id)

  # Return the first instance of the model.
  instances = (value for key, value of DocumentModel.instances[id])
  instances[0]



###
Registers a global handler to invoke before the 'updateFields' method
is invoked on any model.

@param func(model, fields): Function to invoke.

###
DocumentModel.beforeUpdateFields = (func) -> _beforeUpdateFields.push(func) if Object.isFunction(func)
_beforeUpdateFields = []



