###
Represents a field on a model.
###
class Data.FieldDefinition
  ###
  Constructor.
  @param key:        The name of the field.
  @param definition: The field as defined in the schema.
  ###
  constructor: (@key, definition) ->
    def    = definition
    @field = def?.field ? @key

    # Model-ref.
    if def?.modelRef?
      @modelRef = def.modelRef if Object.isFunction(def.modelRef)

    # Has-one ref.
    hasOne = def?.hasOne
    if hasOne?
      for refKey in [ 'key', 'modelRef' ]
        throw new Error("HasOne ref for '#{@key}' does not have a #{refKey}.") unless hasOne[refKey]?

      @hasOne =
        key:        hasOne.key
        modelRef:   hasOne.modelRef

    # Type.
    @type = def.type if def?.type?

    # Default value.
    unless @modelRef?
      if Util.isObject(def)
        @default = def.default
      else
        @default = def


  ###
  Determines whether there is a default value.
  ###
  hasDefault: -> @default isnt undefined


  ###
  Safely generates a new default value.
  ###
  createDefault: ->
    value = @default
    return value() if Object.isFunction(value)
    return value.clone() if Object.isArray(value)
    value



  copyTo: (target) ->
    target.definition = @
    for key, value of @
      target[key] = value unless Object.isFunction(value)



  ###
  Stops the field being reactive.
  ###
  stopReactive: -> delete @_deps


  ###
  Reads the value of the field from the given document.
  @param doc:   The document object to read from.
  @param options:
            - useDefault: Flag indicating if the deafult value should be
                          returned if no value exists .
                          (Default:true)

            - reactive:   Flag indicating if a reactive dependency should
                          be setup for this field.
                          (Default:false)
  ###
  read: (doc, options = {}) ->
    # Setup initial conditions.
    mapTo      = @field
    useDefault = (options.useDefault ? true) is true
    reactive   = (options.reactive ? false) is true

    unless mapTo.indexOf('.') > -1
      # Shallow read.
      value = doc[mapTo]
    else
      # Deep read.
      parts = mapTo.split('.')
      key   = parts.last()
      parts.removeAt(parts.length - 1)
      value = Util.ns.get(doc, parts)[key]

    # Type conversions.
    if @type?
      if @type is Date and not Object.isDate(value)
        if value isnt null and value isnt undefined
          value = new Date(value)

    # Process default values (if required).
    if value is undefined and useDefault is true
      value = @createDefault()

    # Setup reactive dependency (if required).
    if reactive
      @_deps ?= new Deps.Dependency()
      @_deps.depend()

    # Finish up.
    value



  ###
  Writes the field value to the given document.
  @param doc:   The document object to write to.
  @param field: The schema field definition.
  @param value: The value to write.
  ###
  write: (doc, value) ->
    # Setup initial conditions.
    value  = @default if value is undefined
    target = docTarget(@field, doc)

    # Type conversions.
    if @type?
      if @type is Date and Object.isDate(value)
        # Store the date value as a number.
        value = value.getTime()

    # Update the value.
    target.obj[ target.key ] = value
    @_deps?.changed()



  ###
  Deletes the field from the document.
  ###
  delete: (doc) ->
    target = docTarget(@field, doc)
    delete target.obj[target.key]



# PRIVATE --------------------------------------------------------------------------



docTarget = (field, doc) ->
  unless field.indexOf('.') > -1
    # Shallow write.
    return { key:field, obj: doc }

  else
    # Deep write.
    parts  = field.split('.')
    target = doc
    for part, i in parts
      if i is parts.length - 1
        # write(target, part) # Write value.
        return { key: part, obj: target }

      else
        target[part] ?= {}
        target = target[part]





