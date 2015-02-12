
# Stubs --------------------------------------------------------

stubDoc = null
Stub = null
ParentSchema = null
ChildSchema = null


initStubs = ->
    class ParentSchema extends Data.Schema
      constructor: (fields...) -> super fields,
        parent: 123
        base:   'base'
        noDefault: undefined
        nullDefault: null

        foo:
          default: 123
          field: 'custom.path'

        mappedShallow:  { field: 'shallow',    default:123 }
        mappedDeep:     { field: 'deep.to.path',  default:123 }
        mappedUndefined: { field: 'deep.to.undefined',  default:undefined }


    class ChildSchema extends ParentSchema
      constructor: -> super
        child: 'abc'
        base:  'overridden'

    class Stub extends Data.Model
      constructor: (doc) ->
        super doc, ChildSchema






# ----------------------------------------------------------------------


describe 'Model.isModelType (class property)', ->
  ParentModel = null
  ChildModel = null
  beforeEach ->
    class ParentModel extends Data.Model
    class ChildModel extends ParentModel

  it 'is a model (parent)', ->
    expect(ParentModel.isModelType).to.equal true

  it 'is a model (child)', ->
    expect(ChildModel.isModelType).to.equal true

  it 'is not a model', ->
    class Foo
    expect(Foo.isModelType).not.to.equal true


# ----------------------------------------------------------------------




describe 'construction and disposal', ->
  beforeEach -> initStubs()

  it 'creates empty document if none is provided in constructor', ->
    class Foo extends Data.Model
    stub = new Foo()
    expect(stub._doc).to.eql {}

  it 'creates empty document for a schema-model if none is provided in constructor', ->
    stub = new Stub()
    expect(stub._doc).to.eql {}


  it 'is flagged as disposed', ->
    stub = new Stub()
    expect(stub.isDisposed).to.equal undefined
    stub.dispose()
    expect(stub.isDisposed).to.equal true



# ----------------------------------------------------------------------


describe 'Model.toValues', ->
  beforeEach -> initStubs()

  it 'stores property-function values', ->
    stub = new Stub()
    stub.foo('My Value')
    values = stub.toValues()
    expect(values.foo).to.equal 'My Value'
    expect(values.parent).to.equal 123
    expect(values.nullDefault).to.equal null
    expect(values.child).to.equal 'abc'
    expect(values.base).to.equal 'overridden'

  it 'stores simple values', ->
    now = new Date()
    stub = new Stub()
    stub.text = 'my text'
    stub.number = 123
    stub.date = now
    stub.bool = true

    values = stub.toValues()
    expect(values.text).to.equal 'my text'
    expect(values.number).to.equal 123
    expect(values.date).to.equal now
    expect(values.bool).to.equal true


  it 'does not store fields starting with "_"', ->
    stub = new Stub()
    stub.__foo = 'My Foo'

    values = stub.toValues()
    expect(values._instance).to.equal undefined
    expect(values.__foo).to.equal undefined



  it 'does not fail when null/undefined field exists', ->
    stub = new Stub()
    stub.foo('My Value')
    stub.yo = null
    stub.toValues()




# ----------------------------------------------------------------------


describe 'Schema', ->
  beforeEach -> initStubs()

  it 'applies schema from schema-Type singlton', ->
    class Foo extends Data.Model
      constructor: -> super null, ChildSchema
    foo = new Foo()
    expect(foo.fields).to.equal ChildSchema.singleton().fields

  it 'applies schema from instance', ->
    schemaInstance = new ChildSchema()
    class Foo extends Data.Model
      constructor: -> super null, schemaInstance
    foo = new Foo()
    expect(foo.fields).to.equal schemaInstance.fields

  it 'throw if schema-Type not passed', ->
    class NotSchema
    class Foo extends Data.Model
      constructor: -> super null, NotSchema
    fn = -> new Foo()
    expect(fn).to.throw /Not a schema Type./

  it 'throw if schema-instance not passed', ->
    class Foo extends Data.Model
      constructor: -> super null, { }
    fn = -> new Foo()
    expect(fn).to.throw /Not a schema instance./

  it 'does not overwrite existing fields', ->
    class Foo extends Data.Model
      constructor: -> super null, ChildSchema
      fields: 'hello'
    foo = new Foo()
    expect(foo.fields).to.equal 'hello'



# ----------------------------------------------------------------------


describe 'fields', ->
  Foo = null
  beforeEach ->
    class Foo extends Data.Model
      constructor: (doc) -> super doc, ChildSchema

  it 'assigns a field function', ->
    stub = new Foo()
    expect(stub.foo).to.be.instanceof Function

  it 'stores name of the function (key)', ->
    stub = new Foo()
    expect(stub.foo.key).to.equal 'foo'

  it 'stores definition of the field', ->
    stub = new Foo()
    expect(stub.foo.definition.key).to.equal 'foo'

  it 'throws if field already exists', ->
    class FooExists extends Data.Model
      constructor: -> super null, ChildSchema
      foo: 'hello'
    fn = -> new FooExists()
    expect(fn).to.throw /The field 'foo' already exists./

  it 'maps to the property name', ->
    stub = new Foo()
    expect(stub.parent.field).to.equal 'parent'

  it 'maps to a custom path', ->
    stub = new Foo()
    expect(stub.foo.field).to.equal 'custom.path'

  it 'default value (implicit)', ->
    stub = new Foo()
    expect(stub.foo.default).to.equal 123

  it 'no default value (implicit)', ->
    stub = new Foo()
    expect(stub.noDefault.default).to.equal undefined

  it 'null default value (implicit)', ->
    stub = new Foo()
    expect(stub.nullDefault.default).to.equal null

  it 'default value (explicit)', ->
    stub = new Foo()
    expect(stub.foo.default).to.equal 123

  it 'does not store default values on document at construction', ->
    stub = new Foo()
    expect(stub._doc).to.eql {}

  it 'sets default values on document via method', ->
    stub = new Foo()
    expect(stub._doc).to.eql {}
    stub.setDefaultValues()
    doc = stub._doc
    expect(doc.parent).to.equal 123
    expect(doc.custom.path).to.equal 123
    expect(doc.nullDefault).to.equal null
    expect(doc.noDefault).to.equal undefined

  it 'does not overwrite existing values when setting default values on the document', ->
    stub = new Foo()
    stub.parent 'my-value'
    stub.setDefaultValues()

    doc = stub._doc
    expect(doc.parent).to.equal 'my-value' # Custom value.
    expect(doc.custom.path).to.equal 123   # Default value.

  it 'returns the model from the [setDefaultValues] method', ->
    stub = new Foo().setDefaultValues()
    expect(stub._doc.custom.path).to.equal 123


  it 'defines parent properties', ->
    stub = new Foo()
    expect(stub.parent.default).to.equal 123

  it 'defines child properties', ->
    stub = new Foo()
    expect(stub.child.default).to.equal 'abc'

  it 'overwrites properties (child)', ->
    class Child extends Data.Model
      constructor: () -> super null, ChildSchema
    stub = new Child()
    expect(stub.base.default).to.equal 'overridden'

  it 'overwrites properties (parent)', ->
    class Parent extends Data.Model
      constructor: () -> super null, ParentSchema
    stub = new Parent()
    expect(stub.base.default).to.equal 'base'


  it 'reads default-value from non-mapped path', ->
    stub = new Foo()
    expect(stub.foo()).to.equal 123

    stub._doc = {} # Blow away the doc. Ensure it can read when value is not in doc.
    expect(stub.foo()).to.equal 123


  it 'reads no value from non-mapped path', ->
    stub = new Foo()
    expect(stub.noDefault()).to.equal undefined

    stub._doc = {} # Blow away the doc. Ensure it can read when value is not in doc.
    expect(stub.noDefault()).to.equal undefined


  it 'reads null value from non-mapped path', ->
    stub = new Foo()
    expect(stub.nullDefault()).to.equal null

    stub._doc = {} # Blow away the doc. Ensure it can read when value is not in doc.
    expect(stub.nullDefault()).to.equal null

  it 'reads from mapped path (shallow)', ->
    stub = new Foo()
    expect(stub.mappedShallow()).to.equal 123

    stub._doc = {} # Blow away the doc. Ensure it can read when value is not in doc.
    expect(stub.mappedShallow()).to.equal 123

  it 'reads default value from mapped path (deep)', ->
    stub = new Foo()
    expect(stub.mappedDeep()).to.equal 123

    stub._doc = {} # Blow away the doc. Ensure it can read when value is not in doc.
    expect(stub.mappedDeep()).to.equal 123

  it 'reads pre-existing value (shallow)', ->
    stub = new Foo({ parent:'my-value' })
    expect(stub.parent()).to.equal 'my-value'

  it 'reads pre-existing value (deep)', ->
    stub = new Foo
      deep:
        to:
          path: 'my-value'
    expect(stub.mappedDeep()).to.equal 'my-value'


  it 'reactively calls back when property is written to', (done) ->
    stub = new Foo()

    count = 0
    Deps.autorun ->
      stub.foo(undefined, reactive:true) # Reactive dependency setup here.
      count += 1

    count = 0
    stub.foo(123) # Change should cause the reactive callback.

    Util.delay ->
      expect(count).to.equal 1
      done()

  it 'reactively calls back multiple times', (done) ->
    stub = new Foo()

    count = 0
    Deps.autorun ->
      stub.foo(undefined, reactive:true)
      count += 1

    count = 0
    stub.foo(1)

    Util.delay ->
      stub.foo(1)
      Util.delay ->
        expect(count).to.equal 2
        done()



  it 'stops reactive callbacks', (done) ->
    stub = new Foo()

    count = 0
    Deps.autorun ->
      stub.foo(undefined, reactive:true)
      count += 1

    count = 0
    stub.foo.definition.stopReactive()
    stub.foo(1)

    Util.delay ->
      expect(count).to.equal 0
      done()


  it 'is reactive from from one read operation, but not another', (done) ->
    stub = new Foo()

    countReactive = 0
    Deps.autorun ->
      stub.foo(undefined, reactive:true)
      countReactive += 1

    countNonReactive = 0
    Deps.autorun ->
      stub.foo(undefined, reactive:false)
      stub.foo(undefined, reactive:null)
      stub.foo()
      countNonReactive += 1

    countReactive = 0
    countNonReactive = 0
    stub.foo(1)

    Util.delay ->
      expect(countReactive).to.equal 1
      expect(countNonReactive).to.equal 0
      done()



  it 'writes value (shallow path)', ->
    stub = new Foo()
    stub._doc = {} # Blow away the doc. Ensure it can write when value is not in doc.
    stub.child 'my-value'
    expect(stub.child()).to.equal 'my-value'
    expect(stub._doc.child).to.equal 'my-value'

  it 'writes value (deep path)', ->
    stub = new Foo()
    stub._doc = {} # Blow away the doc. Ensure it can write when value is not in doc.
    stub.mappedDeep 'abc'
    expect(stub._doc.deep.to.path).to.equal 'abc'
    expect(stub.mappedDeep()).to.equal 'abc'

  it 'writes an object', ->
    stub = new Foo()
    stub._doc = {} # Blow away the doc. Ensure it can write when value is not in doc.

    value = { foo:123 }
    stub.mappedDeep value

    expect(stub._doc.deep.to.path).to.equal value
    expect(stub.mappedDeep()).to.equal value

    value.foo = 'abc'
    expect(stub.mappedDeep().foo).to.equal 'abc'


# ----------------------------------------------------------------------


describe 'Deleting field values (setting to undefined)', ->
  class Foo extends Data.Model
    constructor: (doc) ->
      super doc, ChildSchema

  it 'deletes the attribute (shallow path)', ->
    stub = new Foo()
    stub.child 'my-value'
    expect(stub._doc.child).not.to.equal undefined
    stub.child.delete()
    expect(stub._doc.child).to.equal undefined


  it 'deletes to undefined (shallow path)', ->
    stub = new Foo()
    expect(stub.noDefault()).to.equal undefined
    stub.noDefault('foo')
    expect(stub.noDefault()).to.equal 'foo'
    stub.noDefault.delete()
    expect(stub.noDefault()).to.equal undefined


  it 'deletes the attribute (deep path)', ->
    stub = new Foo()
    stub.mappedDeep 'abc'
    expect(stub._doc.deep.to.path).not.to.equal undefined
    stub.mappedDeep.delete()
    expect(stub._doc.deep.to.path).to.equal undefined


  it 'deletes to undefined (deep path)', ->
    stub = new Foo()
    stub.mappedUndefined 'abc'
    expect(stub._doc.deep.to.undefined).not.to.equal undefined
    stub.mappedUndefined.delete()
    expect(stub._doc.deep.to.undefined).to.equal undefined


# ----------------------------------------------------------------------


describe 'Property filters (read) - via function attached to the field', ->
  it 'calls [beforeRead] filter', ->
    stub = new Stub()
    count = 0
    value = null
    stub.foo 'hello'

    stub.foo.beforeRead = (v) ->
        count += 1
        value = v
        value

    expect(stub.foo()).to.equal 'hello' # Read.
    expect(count).to.equal 1
    expect(value).to.equal 'hello'

  it 'mutates the read value', ->
    stub = new Stub()
    stub.foo.beforeRead = (value) -> value.toString().capitalize()
    stub.foo 'hello'
    expect(stub.foo()).to.equal 'Hello'


describe 'Property filters (read) - via function on derived model', ->
  it 'calls [beforeRead] filter', ->
    self  = undefined
    field = undefined
    value = undefined
    count = 0

    class ReadFilterStub extends Stub
      beforeRead: (f, v) ->
        self  = @
        field = f
        value = v
        value

    stub = new ReadFilterStub()
    stub.foo('hello')
    expect(stub.foo()).to.equal 'hello' # Read.
    expect(value).to.equal 'hello'
    expect(field.key).to.equal 'foo'
    expect(self).to.equal stub

  it 'mutates the read value', ->
    class ReadFilterStub extends Stub
      beforeRead: (field, value) ->
        switch field.key
          when 'foo' then value.capitalize?()
          else value

    stub = new ReadFilterStub()
    stub.foo('hello')
    stub.base('my value')
    expect(stub.foo()).to.equal 'Hello'
    expect(stub.base()).to.equal 'my value'



# ----------------------------------------------------------------------


describe 'Write filters - via function attached to the field', ->
  it 'calls the [beforeWrite] filter', ->
    stub = new Stub()
    count = 0
    value = null
    stub.foo.beforeWrite = (v, options) ->
        count += 1
        value = v
        expect(options).to.eql { foo:123 }
        value
    stub.foo 'hello', { foo:123 }
    expect(count).to.equal 1


  it 'mutates the written value', ->
    stub = new Stub()
    stub.foo.beforeWrite = (value) -> 'goodbye'
    stub.foo 'hello'
    expect(stub.foo()).to.equal 'goodbye'


  it 'calls the [afterWrite] filter', ->
    stub = new Stub()
    count = 0
    value = null
    options = null
    stub.foo.afterWrite = (v, o) ->
        count += 1
        value = v
        options = o
    stub.foo 'hello'

    expect(value).to.equal 'hello'
    expect(count).to.equal 1
    expect(options).to.eql { hasChanged:true }

  it 'calls the [afterWrite] filter with no change', ->
    stub = new Stub()
    options = null
    stub.foo.afterWrite = (v, o) -> options = o
    stub.foo 123 # No change.
    expect(options).to.eql { hasChanged:false }

  it 'does not mutate the value via the [afterWrite] filter', ->
    stub = new Stub()
    value = null
    stub.foo.afterWrite = (value) -> 'should not change in [afterWrite] - only [beforeWrite]'
    stub.foo 'hello'
    expect(stub.foo()).to.equal 'hello'

  it 'ignores the [beforeWrite] filter', ->
    stub = new Stub()
    value = null
    stub.foo.beforeWrite = (value) -> 'ignore'
    stub.foo 'hello', ignoreBeforeWrite:true
    expect(stub.foo()).to.equal 'hello'


# ----------------------------------------------------------------------



describe 'Write filters - via function on derived model', ->
  it 'calls the [beforeWrite] filter', ->
    count   = 0
    self    = undefined
    field   = undefined
    value   = undefined
    options = undefined

    class WriteFilterStub extends Stub
      beforeWrite: (f, v, o) ->
        self = @
        field = f
        value = v
        options = o
        count += 1
        expect(options).to.eql { foo:123 }

    stub = new WriteFilterStub()
    stub.foo 'hello', { foo:123 }
    expect(count).to.equal 1
    expect(self).to.equal stub
    expect(field.key).to.equal 'foo'
    expect(value).to.equal 'hello'
    expect(options.foo).to.equal 123
    expect(options.hasChanged).to.equal true

  it 'mutates the written value', ->
    class WriteFilterStub extends Stub
      beforeWrite: (field, value, options) ->
        switch field.key
          when 'foo' then 'goodbye'
          else value

    stub = new WriteFilterStub()
    stub.foo 'hello'
    stub.base(987)
    expect(stub.foo()).to.equal 'goodbye'
    expect(stub.base()).to.equal 987


  it 'calls the [afterWrite] filter', ->
    count   = 0
    self    = undefined
    field   = undefined
    value   = undefined
    options = undefined

    class WriteFilterStub extends Stub
      afterWrite: (f, v, o) ->
        self = @
        field = f
        value = v
        options = o
        count += 1

    stub = new WriteFilterStub()
    stub.foo 'hello'
    expect(count).to.equal 1
    expect(self).to.equal stub
    expect(field.key).to.equal 'foo'
    expect(value).to.equal 'hello'
    expect(options).to.eql { hasChanged:true }
