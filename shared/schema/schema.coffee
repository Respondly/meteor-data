###
Base class for model Schema's
###
Schema = class Data.Schema
  ###
  Constructor.
  @param fields:  Object(s) containing a set of field definitions
                  passed to the [define] method.
  ###
  constructor: (fields...) ->
    # Setup initial conditions.
    @fields = {}

    # Reverse the fields so that child overrides replace parent definitions.
    fields.reverse()

    # Setup the field definitions.
    define = (field) =>
        return unless field?
        for key, value of field
          @fields[key] = new Data.FieldDefinition(key, value)

    define(item) for item in fields.flatten()


  ###
  Creates a new document object populated with the
  default values of the schema.
  @param schema:  The schema to generate the document from.
  ###
  createWithDefaults: ->
    doc = {}
    for key, field of @fields
      if field.hasDefault()
        value = field.createDefault()
        field.write(doc, value)
    doc


# Schema Class Methods ------------------------------------------------------------

Schema.isSchema      = true  # Flag used to identify the type.
Schema.isInitialized = false # Flag indicating if the schema has been initialized.


###
Initializes the schema, copying the field definitions
as class properties.
###
Schema.init = ->
  return @ if @isInitialized is true

  instance = @singleton()
  @fields ?= instance.fields

  for key, value of instance.fields
    @[key] = value

  # Finish up.
  @isInitialized = true
  @



###
Retrieves the singleton instance of the schema.
###
Schema.singleton = ->
  return @_instance if @_instance?
  @_instance = new @()
  @_instance


