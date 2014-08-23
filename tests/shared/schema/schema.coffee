Schema        = null
MySchema      = null
ParentSchema  = null
ChildSchema   = null

initSchemas = ->
  Schema = Data.Schema
  class MySchema extends Schema

  class ParentSchema extends Schema
    constructor: (fields) ->
      super fields,
        parent: 123
        base:   'base'

  class ChildSchema extends ParentSchema
    constructor: () -> super
      child: 'abc'
      base: 'overridden'



describe 'Schema', ->
  beforeEach -> initSchemas()


  it 'assigns a field function with default value', ->
    schema = new MySchema { foo: 123 }
    expect(schema.fields.foo.key).to.equal 'foo'
    expect(schema.fields.foo.default).to.equal 123

  it 'assigns fields from constructor', ->
    schema = new MySchema
                    foo: 123
                    bar: 'abc'
    expect(schema.fields.foo.key).to.equal 'foo'
    expect(schema.fields.bar.key).to.equal 'bar'

  it 'assigns fields from array of fields passed up through inheritance heirarchy', ->
    class Schema1 extends Data.Schema
      constructor: (fields...) -> super fields,
          foo: 'foo'
    class Schema2 extends Schema1
      constructor: (fields...) -> super fields,
          bar: 'bar'

    schema = new Schema2 { baz: 'abc' }
    expect(schema.fields.foo.key).to.equal 'foo'
    expect(schema.fields.bar.key).to.equal 'bar'
    expect(schema.fields.baz.key).to.equal 'baz'



describe 'Schema: mappings', ->
  beforeEach -> initSchemas()

  it 'maps to the property name', ->
    schema = new MySchema( foo: 123 )
    expect(schema.fields.foo.field).to.equal 'foo'

  it 'maps to a custom path', ->
    schema = new MySchema
      foo:
        field: 'custom.field.path'
    expect(schema.fields.foo.field).to.equal 'custom.field.path'



describe 'Schema: default values', ->
  beforeEach -> initSchemas()

  it 'default value (implicit)', ->
    schema = new MySchema
      foo: 123
      bar: -> [1,2,3]
    expect(schema.fields.foo.default).to.equal 123
    expect(schema.fields.bar.default).to.be.an.instanceOf Function
    expect(schema.fields.bar.createDefault()).to.eql [1,2,3]

  it 'clones default array', ->
    defaultArray = [1,2,3]
    schema = new MySchema
      foo: defaultArray
    expect(schema.fields.foo.default).to.equal defaultArray
    expect(schema.fields.foo.createDefault()).not.to.equal defaultArray
    expect(schema.fields.foo.createDefault()).to.eql [1,2,3]

  it 'no default value (implicit)', ->
    schema = new MySchema { foo: undefined }
    expect(schema.fields.foo.default).to.equal undefined

  it 'null default value (implicit)', ->
    schema = new MySchema { foo: null }
    expect(schema.fields.foo.default).to.equal null

  it 'default value (explicit)', ->
    schema = new MySchema
      foo:
        default: 123
      bar:
        default: [1,2,3]
    expect(schema.fields.foo.default).to.equal 123
    expect(schema.fields.bar.default).to.eql [1,2,3]

  it 'default value (object)', ->
    foo = { bar:123 }
    schema = new MySchema
      foo:
        default: foo
    foo.bar = 'abc'
    expect(schema.fields.foo.default.bar).to.equal 'abc'



describe 'Schema: inheritance', ->
  beforeEach -> initSchemas()

  it 'has both parent and child fields', ->
    schema = new ChildSchema()
    expect(schema.fields.parent.default).to.equal 123
    expect(schema.fields.child.default).to.equal 'abc'

  it 'overwrites the parent field', ->
    class Parent extends Schema
      constructor: (fields...) -> super fields,
        foo: 'parent'

    class Child extends Parent
      constructor: -> super
        foo:'child'

    parent = new Parent()
    child  = new Child()
    expect(parent.fields.foo.default).to.equal 'parent'
    expect(child.fields.foo.default).to.equal 'child'


describe 'Schema: class methods (isInitalized flag)', ->
  MySchema1 = null
  MySchema2 = null
  beforeEach ->
    class MySchema1 extends Data.Schema
    class MySchema2 extends MySchema1

  it 'is not initialized by default', ->
    expect(MySchema1.isInitialized).to.equal false
    expect(MySchema2.isInitialized).to.equal false

  it 'sets flag on child schema to true', ->
    MySchema2.init()
    expect(MySchema1.isInitialized).to.equal false
    expect(MySchema2.isInitialized).to.equal true

  it 'sets flag on base schema to true', ->
    MySchema1.init()
    expect(MySchema1.isInitialized).to.equal true
    expect(MySchema2.isInitialized).to.equal false


describe 'Schema: class methods (.init)', ->
  beforeEach -> initSchemas()

  it 'stores the singleton instance', ->
    expect(ChildSchema._instance).to.equal undefined
    ChildSchema.init()
    expect(ChildSchema._instance).to.be.instanceof ChildSchema
    expect(ChildSchema._instance).to.equal ChildSchema.singleton()

  it 'copies field definitions onto the class', ->
    ChildSchema.init()
    expect(ChildSchema.parent.default).to.equal 123
    expect(ChildSchema.child.default).to.equal 'abc'

  it 'redefines a method on a child schema', ->
    ParentSchema.init()
    ChildSchema.init()

    expect(ParentSchema.base.default).to.equal 'base'
    expect(ChildSchema.base.default).to.equal 'overridden'

  it 'stores fields as property', ->
    ChildSchema.init()
    expect(ChildSchema.fields).to.exist
    expect(ChildSchema.fields.parent.default).to.equal 123
    expect(ChildSchema.fields.child.default).to.equal 'abc'

  it 'does not overwrite existing fields as property', ->
    fn = ->
    ChildSchema.fields = fn
    ChildSchema.init()
    expect(ChildSchema.fields).to.equal fn


describe 'Schema: singleton', ->
  beforeEach -> initSchemas()

  SingletonSchema = null
  beforeEach ->
    class SingletonSchema extends Schema

  it 'does not have instance by default', ->
    expect(SingletonSchema._instance).to.equal undefined

  it 'creates singleton instance', ->
    singleton1 = SingletonSchema.singleton()
    singleton2 = SingletonSchema.singleton()
    expect(singleton1).to.equal singleton2
    expect(singleton1).to.equal SingletonSchema._instance

  it 'creates type appropriate instances', ->
    expect(ParentSchema.singleton()).to.be.an.instanceof ParentSchema
    expect(ChildSchema.singleton()).to.be.an.instanceof ChildSchema


describe 'reading and writing', ->
  ClassSchema = null
  classSchema = null
  doc         = null

  beforeEach ->
    class ClassSchema extends Schema
      constructor: -> super
        root:           null
        rootDefault:    'hello'
        rootUndefined:  undefined
        deep:
          field: 'path.to.child'
        deepDefault:
          default: 'hello'
          field: 'path.to.deepDefault'
        deepNull:
          default: null
          field: 'path.to.deepNull'
        deepUndefined:
          field: 'deep.path.to.undefined'

    classSchema = new ClassSchema()
    doc =
      root: 'root'
      path:
        to:
          child: 'deep'

  it 'reads shallow value', ->
    value = classSchema.fields.root.read(doc)
    expect(value).to.equal 'root'

  it 'reads deep value', ->
    value = classSchema.fields.deep.read(doc)
    expect(value).to.equal 'deep'

  it 'reads deep value (default)', ->
    value = classSchema.fields.deepDefault.read(doc)
    expect(value).to.equal 'hello'

  it 'reads deep value (null)', ->
    value = classSchema.fields.deepNull.read(doc)
    expect(value).to.equal null

  it 'reads deep value (undefined)', ->
    value = classSchema.fields.deepUndefined.read(doc)
    expect(value).to.equal undefined



  it 'writes shallow value', ->
    classSchema.fields.root.write(doc, 'foo')
    expect(doc.root).to.equal 'foo'

  it 'writes over existing deep value', ->
    classSchema.fields.deep.write(doc, 'bar')
    expect(doc.path.to.child).to.equal 'bar'

  it 'writes new deep value', ->
    classSchema.fields.deepDefault.write(doc, 'foo')
    expect(doc.path.to.deepDefault).to.equal 'foo'

  it 'writes null value to field with no default value', ->
    classSchema.fields.deepUndefined.write(doc, null)
    expect(doc.deep.path.to.undefined).to.equal null

  it 'writes undefined value to field with no default value (temp)', ->
    # NB: This should eventually remove the field (and/or path to field).
    classSchema.fields.deepUndefined.write(doc, undefined)
    expect(doc.deep.path.to.undefined).to.equal undefined

  it 'writes default value when passed undefined (shallow)', ->
    classSchema.fields.rootDefault.write(doc, 123)
    expect(doc.rootDefault).to.equal 123

    classSchema.fields.rootDefault.write(doc, undefined)
    expect(doc.rootDefault).to.equal 'hello'

  it 'writes default value when passed undefined (deep)', ->
    classSchema.fields.deepDefault.write(doc, 123)
    expect(doc.path.to.deepDefault).to.equal 123

    classSchema.fields.deepDefault.write(doc, undefined)
    expect(doc.path.to.deepDefault).to.equal 'hello'


describe '.createWithDefaults()', ->
  obj = { foo:123 }
  DefaultsSchema = null
  schema = null
  doc    = null

  beforeEach ->
    class DefaultsSchema extends ParentSchema
      constructor: -> super
        noDefault: undefined
        noDefaultPath:
          default: undefined
          field:   'noDefault.path.to.field'

        nullValue: null
        nullValuePath:
          default: null
          field:   'path.to.nullValue'

        type: 'MyType'
        stringValue: 'hello'
        stringValuePath:
          default:  'hello'
          field:    'path.to.stringValue'

        arrayValue: []
        arrayValueDeep:
          default: []
          field:   'path.to.arrayValue'

        funcValue:
          default: -> obj

        funcValuePath:
          default: -> obj
          field:     'path.to.funcValue'

    schema = new DefaultsSchema()
    doc    = schema.createWithDefaults()

  it 'has default values', ->
    expect(doc.nullValue).to.equal null
    expect(doc.path.to.nullValue).to.equal null
    expect(doc.type).to.equal 'MyType'
    expect(doc.stringValue).to.equal 'hello'
    expect(doc.path.to.stringValue).to.equal 'hello'
    expect(doc.arrayValue).to.eql []
    expect(doc.path.to.arrayValue).to.eql []
    expect(doc.funcValue).to.equal obj
    expect(doc.path.to.funcValue).to.equal obj

  it 'has does not have values for undefined fields', ->
    expect(doc.noDefault).not.to.exist
    expect(doc.path.to.noDefault).not.to.exist

