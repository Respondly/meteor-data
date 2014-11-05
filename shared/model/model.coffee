#= require ../ns.js
#= base

instanceCount = 0


###
Base class models.

This provides a way of wrapping model logic around
a document instance.
###
Data.Model = class Model extends AutoRun
  ###
  Constructor.
  @param doc:     The document instance being wrapped.
  @param schema:  The schema Type (or an instance) that defines the model's properties.
  ###
  constructor: (doc, schema) ->
    super
    instanceCount += 1
    @_instance     = instanceCount
    @_schema       = schema
    @_init(doc)


  _init: (doc) ->
    @_doc = doc ? {}
    unless @fields
      # First time initialization.
      if @_schema?
        applySchema(@) if @_schema?
        applyModelRefs(@, overwrite:false)
    else
      # This is a refresh of the document.
      applyModelRefs(@, overwrite:true)



  ###
  Retrieves the schema instance that defines the model.
  ###
  schema: ->
    # Setup initial conditions.
    return unless @_schema

    # Ensure the value is a Schema instance.
    if Object.isFunction( @_schema )
      throw new Error('Not a schema Type.') unless @_schema.isSchema is yes
      @_schema = @_schema.singleton()
    else
      throw new Error('Not a schema instance.') unless (@_schema instanceof Data.Schema)

    # Finish up.
    @_schema


  ###
  Merges into the models document default values from the
  schema for values that are not already present.
  ###
  setDefaultValues: ->
    # Setup initial conditions.
    schema = @schema()
    return @ unless schema

    # Write each field.
    for key, field of schema.fields
      if field.hasDefault()
        existingValue = field.read(@_doc, useDefault:false)
        if existingValue is undefined
          @[key](field.createDefault())

    # Finish up.
    @


  ###
  Determines whether this is a sub-model.
  ###
  isSubModel: -> (@parentField instanceof Data.FieldDefinition)


  ###
  REACTIVE: Gets or sets changed values.
  @returns options
              - field:  (optional) When writing, the field that has changed.
              - value:  (optional) When writing, the new value of the changed field.  Pass [undefined] to remove.
              - clear:  (optional) Flag indicating if changed values
                        should be cleared (default:false).

  @returns an object containing [fields:values] that have changed,
           or [null] if there have been no changes.
  ###
  changes: (options = {}) ->

    reactiveStore = @__internal__.changeStore ?= new ReactiveHash()

    read = =>
        result = reactiveStore.get('changes') ? null

        for key, value of result
            # Clean out any empty objects (from sub-models).
            delete result[key] if Util.isObject(value) and Object.isEmpty(value)
            delete result[key] if value is null

        # Read operation.
        return null if result and Object.isEmpty(result)
        return result


    write = (value) =>
        if value isnt undefined
          # WRITE.
          reactiveStore.set 'changes', value
          if value is null
            # The value is being deleted.
            if @isSubModel()
              # Delete this sub-model's reference in the parent change-set too.
              delete @parentModel.changes()?[@parentField.key]


    # Read operation (if no options were specified).
    return read() if Object.isEmpty(options)

    # Clear value.
    if options.clear
      write(null)
      return null

    # Write value.
    if key = options.key
      changes = read() ? {}
      value   = options.value
      value   = Util.clone(value)

      if (@[key] instanceof Model)
        # This is a sub-model.
        #     If the value already exists, merge in existing changes to avoid losing data,
        #     as each field on the object represents a unique property-function on the sub-model.
        if value is undefined
          delete changes[key]
        else
          if changes[key] and Util.isObject(value)
            Object.merge( changes[key], value, false )
          else
            changes[key] = value

      else

        # This is a normal property-function, overwrite the changes.
        if value is undefined
          delete changes[key]
        else
          if priorChange = changes[key]
            # This property has already been changed.
            sameAsOriginal = Object.equal(priorChange.from, value)
            if sameAsOriginal
              delete changes[key] # The value has been reverted back to it's original state.  Remove the change.
            else
              priorChange.to = value # Store the value keeping the original [from] value intact.

          else
            # This is the first time the change for this property is being stored.
            # Keep a copy of the original [from] value.
            currentValue = @[key]()
            unless Object.equal(currentValue, value)
              changes[key] =
                to:   value
                from: Util.clone(currentValue) # Clone the from value so that references don't change.

      # Store the change-set.
      changes = null if Object.isEmpty(changes)
      write(changes)

    # Finish up.
    read()


  ###
  Updates a model from the given change-set.
  @param changes:   The change-set (see the [changes] method).
                    If not specified the current [changes] state is used.
  @returns an array of changed field definitions.
  ###
  syncChanges: (changes) ->
    changes ?= @changes()
    Model.syncChanges(@, changes)


  ###
  Reverts a model's changes.
  @returns the reverted changes.
  ###
  revertChanges: -> Model.revertChanges(@)



  ###
  Logs the model to the console.
  @param model: The model object to log.
  @param props: An [args...] array of property names to write out.
  @param options:
            - title: (Optional) A title to use for the model.
  ###
  log: (props...) -> Model.log(@, props)




# CLASS METHODS -----------------------------------------------------------------


Model.isModelType = true # Flag used to identify the type.


###
Gets the type name of the given model instance
@param instance: The instance of the model to examine.
###
Model.typeName = (instance) -> instance?.__proto__.constructor.name



###
Updates a model from the given change-set.
@param model:     The target model to update.
@param changes:   The change-set (see the [changes] method).
@returns an array of changed field definitions.
###
Model.syncChanges = (model, changes = {}) ->
  fields = []

  for key, value of changes
    member = model[key]
    fields.push( model.fields[key] )

    if Object.isFunction(member)
      model[key](value.to) # Write to the property function.

    if (member instanceof Data.Model)
      Model.syncChanges(model[key], value) # <= RECURSION : update the sub-document.

  # Finish up.
  fields


###
Reverts a model's changes.
@param model: The target model to update.
@returns the reverted changes.
###
Model.revertChanges = (model) ->
  if changes = model?.changes()
    changes = Object.clone(changes)
    for key, change of changes
      if Object.isFunction(model[key])
        model[key](change.from) # Update the member function with the original value.

      if (model[key] instanceof Data.Model)
        Model.revertChanges(model[key]) # <= RECURSION : update the sub-document.

  # Finish up.
  model.changes(clear:true)
  changes


###
Compares the models change-set with it's current values.
This is useful for determining whether the model has been changed out by another
client, and that the local changes are stale.

@param model:   The model to examine.
@param changes: Optional. The specific change-set to examine

###
Model.compareChanges = (model, changes = null) ->
  # Setup initial conditions.
  changes ?= model?.changes()
  result = { isStale:false }
  return result unless changes

  # Perform the value comparisons.
  compare = (model, changes) ->
        for key, change of changes
          if Object.isFunction(model[key])
            # Compare the change-set's values with the current value on the model.
            currentValue = model[key]()
            equalsFromValue = Object.equal(currentValue, change.from)

            if not Object.equal(currentValue, change.from)
              if not Object.equal(currentValue, change.to)
                change.current = currentValue
                change.isStale = true
                result.isStale = true

          if (model[key] instanceof Data.Model)
            compare(model[key], changes[key]) # <= RECURSION : update the sub-document.

        changes

  compare(model, changes)

  # Finish up.
  result.changes = changes
  result



###
Logs the model to the console.
@param model: The model object to log.
@param props: An [args...] array of property names to write out.
@param options:
          - title: (Optional) A title to use for the model.
###
Model.log = (model, props...) ->
  # Setup initial conditions.
  return unless model
  props = props.flatten().compact()

  # Extract the options from the props array.
  options = {}
  if Object.isObject(props.last())
    options = props.last()
    props = props.removeAt(props.length - 1)

  # Write the model (with or without a title).
  if title = options.title
    console.log title, model
  else
    console.log model

  writeProp = (name, label) ->
        convertToString = false
        parts = name.split('.')
        name = parts[0] if parts.length > 0
        convertToString = true if parts[1] is 'toString' if parts.length > 1

        value = model[name]
        value = value.call(model) if Object.isFunction(value)

        if Util.isObject(value)
          convertToString = true if Meteor.isServer

        if Object.isDate(value)
          value = "#{ value.toString() } | #{ value.secondsAgo() } seconds ago."

        if convertToString
          value = value?.toString?()

        label = name unless label
        console.log " - #{ label }:", value

  # Write props.
  writeProp('id')
  writeProp('_doc', 'doc')
  writeProp(name) for name in props

  # Finish up.
  console.log ''




# PRIVATE --------------------------------------------------------------------------



assign = (model, key, value, options = {}) ->
    unless options.overwrite is true
      throw new Error("The field '#{key}' already exists.") if model[key] isnt undefined
    model[key] = value



applySchema = (model) ->
  schema = model.schema()

  # Store a reference to the fields.
  model.fields ?= schema.fields

  # Apply fields.
  for key, value of schema.fields
    unless value.modelRef?
      # Assign a read/write property-function.
      assign( model, key, fnField(value, model) )

    if value.hasOne?
      assign model, value.hasOne.key, fnHasOne(value, model)



applyModelRefs = (model, options = {}) ->
  schema = model.schema()
  for key, value of schema.fields
    if value.modelRef?

      # Assign an instance of the referenced model.
      # NB: Assumes the first parameter of the constructor is the document.
      doc      = Util.ns.get(model._doc, value.field)
      instance = new value.modelRef(doc)

      # Check if the function returns the Type (rather than the instance).
      if Object.isFunction(instance) and instance.isModelType
        instance = new instance(doc)

      # Store the model-ref parent details.
      instance.parentModel = model
      instance.parentField = value

      # Assign the property-function.
      assign model, key, instance, options



fnField = (field, model) ->
  fn = (value, options = {}) ->
          # Setup initial conditions.
          doc = model._doc
          parentModel = model.parentModel
          parentField = model.parentField

          # Write value.
          if value isnt undefined
            # Pre-write filter.
            #   - Example:
            #         model.foo.beforeWrite = (value, options) -> return value
            value = beforeWriteFilter(@, field, value, options)
            hasChanged = value isnt field.read(doc, options)

            # If a change is not detected on the underlying document,
            # do a comparison with the change-set.
            if not hasChanged
              if @isSubModel()
                changeSetField = parentModel.changes()?[parentField.key]?[field.key]
              else
                changeSetField = @changes()?[field.key]

              if changeSetField
                hasChanged = true if not Object.equal(value, changeSetField.to)

            options.hasChanged = hasChanged

            # Store a reference to the change ("is dirty").
            if hasChanged
              changes = model.changes( key:field.key, value:value )
              if model.isSubModel()
                # This is a sub-model, register changes on the parent.
                parentModel.changes( key:parentField.key, value:changes )

            # Perform the write.
            field.write(doc, value)

            # Post-write filter.
            #   - Example:
            #         model.foo.afterWrite = (value, options) ->
            afterWriteFilter(@, field, value, options)

            # Persist to mongo DB (if requested).
            if options?.save is true
              if model.updateFields?
                # This is a [DocumentModel] that can be directly updated.
                model.updateFields?(field)
              else
                if parent?.model.updateFields?
                  # This is a sub-document model. Update on the parent.
                  parentModel.updateFields?(parentField)

          # Read value.
          #   - Example:
          #         model.foo.beforeRead = (value) ->
          value = field.read(doc, options)
          value = readFilter(@, field, value)
          value

  # Finish up.
  copyCommonFunctionProperties(fn, field, model)
  fn



fnDelete = (field) ->
  ->
    field.delete(@model._doc)



fnHasOne = (field, model) ->
  fn = (value, options = {}) ->
          read = =>
                # Setup initial conditions.
                hasOne      = field.hasOne
                privateKey  = '_' + hasOne.key

                # Look up the ID of the referenced model.
                idRef = @[field.key]()
                return unless idRef?

                # Check whether the model has already been cached.
                isCached = @[privateKey]? and @[privateKey].id is idRef
                return @[privateKey] if isCached

                # Construct the model from the factory.
                result = hasOne.modelRef.call(model, idRef)
                @[privateKey] = result

          write = =>
                # Store the ID of the written object in the ref field.
                value = beforeWriteFilter(@, field, value.id, options)
                options ?= {}
                options.ignoreBeforeWrite = true
                @[field.key] value, options

          # Read and write.
          write() if value isnt undefined
          read()

  # Finish up.
  copyCommonFunctionProperties(fn, field, model)
  fn


copyCommonFunctionProperties = (fn, field, model) ->
  field.copyTo(fn)
  fn.def    = field
  fn.model  = model
  fn.delete = fnDelete(field)
  fn



# READ/WRITE FILTERS --------------------------------------------------------------------------



beforeWriteFilter = (model, field, value, options) ->
  return value if options?.ignoreBeforeWrite is true
  writeFilter(model, field, value, options, 'beforeWrite')

afterWriteFilter = (model, field, value, options) ->
  return value if options?.ignoreAfterWrite is true
  writeFilter(model, field, value, options, 'afterWrite')


writeFilter = (model, field, value, options, filterKey) ->
  # Attached function.
  func = model[field.key][filterKey]
  value = func(value, options) if Object.isFunction(func)

  # Derived method.
  func = model[filterKey]
  value = func.call(model, field, value, options) if Object.isFunction(func)

  # Finish up.
  value


readFilter = (model, field, value) ->
  # Attached function.
  func = model[field.key]?.beforeRead
  value = func(value) if Object.isFunction(func)

  # Derived method.
  func = model.beforeRead
  value = func.call(model, field, value) if Object.isFunction(func)

  # Finish up.
  value



