#= require ./model
Model = Data.Model
singletonManagers = {}



###
TODO
- Method: toConversation

  db
    collection

- remove other _fields
- reactive updates with DB
- make `session` available only on client.
- singleton not caching it's own models


###



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
    @__internal__.collection = collection
    @id = @_doc._id

    # Store a reference to the model.
    if @id
      Data.models[@id] = @



  ###
  Disposes of the object.
  ###
  dispose: ->
    super
    @_session?.dispose()
    delete @_session
    delete Data.models[@id]


  ###
  Retrieves the scoped session for the model.
  This can be used client-side for storing view state information.
  ###
  session: ->
    return if @isDisposed
    @_session = DocumentModel.session(@) unless @_session?
    @_session


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
    newId = @__internal__.collection.insert(doc)
    doc._id = newId
    @id = newId
    Data.models[@id] = @

    # Finish up.
    @__internal__.changeStore?.clear?()
    @


  ###
  OVERRIDE: Merges into the models document default values from the
  schema for values that are not already present.
  ###
  setDefaultValues: ->
    # Setup initial conditions.
    result  = super
    changes = @changes()
    now     = +(new Date())

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
    @__internal__.collection.update(@defaultSelector(), updates, options)


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
      updatedAt = @fields.updatedAt
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
    @__internal__.collection.remove( @defaultSelector() )
    @dispose()


  ###
  Re-queries the document from the collection.
  ###
  refresh: ->
    collection = @__internal__.collection
    return unless collection? and @_schema?
    doc = collection.findOne( @id )
    @_init( doc ) if doc?
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


###
Gets the scoped-session singleton for the given model instance.
@param instance: The [DocumentModel] instance to retrieve the session for.
###
DocumentModel.session = (instance) ->
  return unless instance?.id?
  ScopedSession.singleton( "#{ Model.typeName(instance) }:#{instance.id}" )


###
Retrieves a singleton instance of a model.
@param id:        The model/document ID.
@param fnFactory: The factory method (or Type) to create the model with if it does not already exist.
###
DocumentModel.singleton = (id, fnFactory) ->
  # Setup initial conditions.
  return unless id?
  doc = id if id._id
  id  = doc._id if doc?

  # Create the instance if necessary.
  unless instances[id]?
    if fnFactory?.isDocumentModelType and doc?
      # Create from Type.
      instances[id] = new fnFactory(doc)

    else if Object.isFunction(fnFactory)
      # Create from factory function.
      instances[id] = fnFactory?(id)

  # Retrieve the model.
  model = instances[id]
  manageSingletons(model?._collection) # Ensure singletons are removed.
  model

DocumentModel.instances = instances = {}
manageSingletons = do ->
  collections = {}
  (col) ->
        return unless col?
        return if collections[col._name]?
        collections[col._name] = col
        col.find().observe
          removed: (oldDoc) ->
                      id    = oldDoc._id
                      model = instances[id]
                      model?.dispose()
                      delete instances[id]




###
Writes a debug log of the model instances.
###
instances.write = ->
  items = []
  add = (instance) -> items.add(instance) unless Object.isFunction(value)
  add(value) for key, value of instances
  console.log "DocumentModel.instances (singletons): #{items.length}"
  for instance in items
    console.log ' > ', instance




###
Registers a global handler to invoke before the 'updateFields' method
is invoked on any model.

@param func(model, fields): Function to invoke.

###
DocumentModel.beforeUpdateFields = (func) -> _beforeUpdateFields.push(func) if Object.isFunction(func)
_beforeUpdateFields = []



