
###
A collection of models that correspond to an array of references.
###
class Data.ModelRefsCollection
  ###
  @param parent:        The parent model.
  @param refsKey:       The key of the property-function that contains the array.
  @param fnFactory(id): Factory method that creates a new model from the given id.
  ###
  constructor: (@parent, @refsKey, @fnFactory) ->
    throw new Error("[#{@refsKey}] not found") unless @parent && @parent[@refsKey]


  ###
  The total number of parents of the particle.
  ###
  count: -> @refs().length


  ###
  Determines whether the collection is empty.
  ###
  isEmpty: -> @count() is 0


  ###
  Retrieves the collection of refs
  ###
  refs: ->
    # NB: A clone of the array is made so that alterations to it here
    #     do not immediately show up in the model's document, thereby allowing
    #     the "changes" comparison to work correctly.
    Util.clone(@readFromParent()) ? []


  ###
  Creates an array of  of models.
  @param refs: (optional) the ID references to convert.
                Retrieved from current state if ommited.
  ###
  toModels: (refs = null) ->
    return [] unless @fnFactory
    refs ?= @refs()
    result = refs.map (id) => @fnFactory(id)
    result.compact()


  ###
  Runs a function against each model in the collection.
  @param func(model): The function to run.
  ###
  each: (func) -> @toModels().each(func)


  ###
  Determines whether the given model exists within the collection.
  @param model: The model (or ID) to look for.
  ###
  contains: (model) ->
    return false unless model?
    id = model.id ? model
    if id
      @refs().indexOf(id) isnt -1
    else
      false



  ###
  Adds a new model to the collection.
  @param model: The model(s), or the model(s) ID's, to add.
  @param options
            - save: Flag indicating if the parent refs array should
                    be updated in the DB (default:true)
  ###
  add: (model, options = {}) ->
    # Setup initial conditions.
    model        = [model] unless Object.isArray(model)
    originalSave = options.save ? true
    options.save = false

    add = (item) =>
              if Util.isObject(item)
                item.insertNew() unless item.id
              id   = item.id ? item
              refs = @refs()
              return if refs.find (ref) -> ref is id # Don't add duplicates.

              # Add the reference.
              refs.add(id)
              @writeToParent(refs, options)

    add(m) for m in model.compact()

    # Finish up.
    @_saveParentRefs() if originalSave is true
    @


  ###
  Removes the given object.
  @param model: The model(s), or the model(s) ID's, to remove.
  @param options
            - save: Flag indicating if the parent refs array should
                    be updated in the DB (default:true)
  ###
  remove: (model, options = {}) ->
    # Setup initial conditions.
    model        = [model] unless Object.isArray(model)
    originalSave = options.save ? true
    options.save = false

    remove = (item) =>
          id   = item.id ? item
          refs = @refs()
          beforeCount = refs.length

          # Attempt to remove the reference.
          refs.remove (item) -> item is id
          if refs.length isnt beforeCount
            # An item was removed.
            @writeToParent(refs, options)

    remove(m) for m in model.compact()

    # Finish up.
    @_saveParentRefs() if originalSave is true
    @


  ###
  Removes all parent references.
  @param options
            - save: Flag indicating if the particle models should
                    be updated in the DB (default:true)
  ###
  clear: (options = {}) ->
    options.save ?= true
    @writeToParent([], options)
    @



  ###
  Updates to the parent property-function array with the given value.
  @param value:    The value to write.
  @param options:  (optional) The options to pass to the property-function.
  ###
  writeToParent: (value, options) -> @parent[@refsKey](value, options)


  ###
  Reads the parent property-function.
  ###
  readFromParent: -> @parent[@refsKey]()


  # PRIVATE --------------------------------------------------------------------------


  _saveParentRefs: ->
    field = @parent.db.fields[@refsKey]
    @parent.updateFields(field)





