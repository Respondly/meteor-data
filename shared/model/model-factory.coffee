###
A factory for models.
###
class Data.ModelFactory
  ###
  Constructor.
  @param collection: The Mongo collection, or the name of the collection
  @param Model:      The model type
  ###
  constructor: (@collection, @ModelType) ->
    @collection     = new Meteor.Collection(@collection) if Object.isString(@collection)
    @_beforeInsert  = new Handlers(@)
    @_afterCreate   = new Handlers(@)


  dispose: ->
    @_beforeInsert.dispose()
    @_afterCreate.dispose()



  # INSERT --------------------------------------------------------------------------------


  ###
  Creates a new instance of the model in the DB.
  @param options:
            - id (optional): A specific ID string to use.
            - ... Any other property values to write.
  ###
  insertNew: (options = {}) ->

    # Construct the model and assign initial property values.
    model = @_createModel(null)
    for key, value of options
      switch key
        when 'id' then # Ignore.
        else
          model[key](value) if Object.isFunction(model[key])

    # Finish up.
    @_beforeInsert.invoke(model)
    @onInsertNew(model, options)



  ###
  OVERRIDABLE: Creates a new instance of the model in the DB.
  @param options:
            - id (optional) A specific ID string to use.
  ###
  onInsertNew: (model, options = {}) ->
    args = {}

    # Pass in a specific ID if specified.
    id = options.id
    args.id = id if Object.isString(id)

    # Perform the DB insertion.
    model.insertNew(args)



  ###
  Registers a handler to invoke before a new model is inserted into the DB.
  NOTE: Use this handler to perform common initialization before a new model is saved.

  @param func(model): The handler to invoke.
  ###
  beforeInsert: (func) -> @_beforeInsert.push(func)



  # CREATE MODEL --------------------------------------------------------------------------



  ###
  OVERRIDABLE: Creates a new model.
  ###
  onCreate: (doc) -> new @ModelType(doc, @)


  ###
  Registers a handler to invoke after a model instance has been created.
  NOTE: Use this handler to perform common initialization on models.
  @param func(model): The handler to invoke.
  ###
  afterCreate: (func) -> @_afterCreate.push(func)



  ###
  Retrieves the specified model if it exists, otherwise creates a new instance it.
  @param id:  The ID of the model.
              Also accepts {id:value} object.
  ###
  getOrCreate: (id) ->
    id = id.id if Util.isObject(id) # Convert {id} to simple ID value.
    id = null if Util.isBlank(id)
    return model if model = @findOne(id)
    @insertNew(id:id)



  # FIND ----------------------------------------------------------------------------------

  ###
  Determines whether the specified model exists.
  @param selector: The ID of the model or a Mongo selector.
  ###
  exists: (selector) -> @findOne(selector)?



  ###
  OVERRIDABLE: Finds a single model.
  @param selector: The ID of the model or a Mongo selector.
  ###
  findOne: (selector) ->
    return null unless selector?
    selector = { _id:selector } if Object.isString(selector)
    @find(selector)[0]



  ###
  OVERRIDABLE: Finds the given models.
  @param selector: The Mongo selector.
  @param options:
             - as: The return type (values: 'models', 'cursor').  Default:'models'
  ###
  find: (selector = {}, options = {}) ->
    cursor = @collection.find(selector, options)
    switch (options.as ? 'models')
      when 'cursor' then cursor
      when 'models' then cursor.map (doc) => @_createModel(doc)



  # PRIVATE -------------------------------------------------------------------------------



  _createModel: (doc) ->
    model = @onCreate(doc)
    @_afterCreate.invoke(model)
    model


