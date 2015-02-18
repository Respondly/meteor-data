ParentSchema  = null
RefSchema     = null
ParentModel   = null
RefModel      = null
parent        = null
children      = null


class ParentSchema extends Data.Schema
  constructor: -> super
    refs: []

class RefSchema extends Data.Schema
  constructor: -> super
    name: null

class ParentModel extends Data.DocumentModel
  constructor: (doc) ->
    super doc, ParentSchema, TestModels
    fnFactory = (id) ->
              doc = TestModels.findOne(id)
              new RefModel(doc) if doc?

    @children = new Data.ModelRefsCollection( @, 'refs', fnFactory )

class RefModel extends Data.DocumentModel
  constructor: (doc) ->
    super doc, RefSchema, TestModels



initStubs = ->
  TestModel.deleteAll()
  parent   = new ParentModel().insertNew()
  children = parent.children





describe 'RefsCollection', ->
  beforeEach -> initStubs()

  it 'has the parent reference', ->
    expect(children.parent).to.equal parent

  it 'isEmpty', ->
    expect(children.isEmpty()).to.equal true


describe 'RefsCollection: adding', ->
  beforeEach -> initStubs()
  it 'stores a reference in the parent refs array', ->
    foo1 = new RefModel()
    foo2 = new RefModel()

    children.add(foo1)
    children.add(foo2)
    expect(children.count()).to.equal 2
    expect(parent.refs().indexOf(foo1.id)).not.to.equal -1
    expect(children.refs().indexOf(foo2.id)).not.to.equal -1

  it 'adds via ID', ->
    foo = new RefModel().insertNew()
    children.add(foo.id)
    expect(children.count()).to.equal 1
    expect(parent.refs().indexOf(foo.id)).not.to.equal -1

  it 'adds an array', ->
    foo1 = new RefModel()
    foo2 = new RefModel()

    children.add([foo1, foo2])
    expect(children.count()).to.equal 2
    expect(children.refs().indexOf(foo1.id)).not.to.equal -1
    expect(children.refs().indexOf(foo2.id)).not.to.equal -1


  it 'does not save the ref', ->
    foo = new RefModel()
    children.add(foo, save:false)
    doc = TestModels.findOne(parent.id)
    expect(doc.refs.indexOf(foo.id)).to.equal -1

  it 'saves the ref by default', ->
    foo = new RefModel()
    children.add(foo)
    doc = TestModels.findOne(parent.id)
    expect(doc.refs.indexOf(foo.id)).to.equal 0

  it 'does not add the same item twice', ->
    foo = new RefModel()
    children.add(foo)
    children.add(foo)
    children.add(foo)
    expect(children.count()).to.equal 1



describe 'RefsCollection: remove', ->
  beforeEach -> initStubs()

  it 'does nothing when null is passed to remove', ->
    foo = new RefModel()
    children.add(foo)
    children.remove()
    children.remove(null)
    expect(children.count()).to.equal 1

  it 'removes the given item', ->
    foo = new RefModel()
    children.add(foo)
    children.remove(foo)
    expect(children.count()).to.equal 0

  it 'removes the given array of item', ->
    foo1 = new RefModel()
    foo2 = new RefModel()
    foo3 = new RefModel()
    children.add([foo1, foo2, foo3])
    children.remove([foo1, foo3])
    expect(children.count()).to.equal 1
    expect(children.refs().indexOf(foo2.id)).to.equal 0

  it 'removes the via ID referecne', ->
    foo = new RefModel().insertNew()
    children.add(foo)
    children.remove(foo.id)
    expect(children.count()).to.equal 0

  it 'saves removals by default', ->
    foo = new RefModel()
    children.add(foo)
    children.remove(foo)
    doc = TestModels.findOne(parent.id)
    expect(doc.refs.length).to.equal 0

  it 'does not save the removal', ->
    foo = new RefModel()
    children.add(foo)
    children.remove(foo, save:false)
    doc = TestModels.findOne(parent.id)
    expect(doc.refs.length).to.equal 1
    expect(doc.refs[0]).to.equal foo.id


describe 'RefsCollection: clear', ->
  beforeEach ->
    initStubs()
    for i in [1..3]
      children.add(new RefModel())
    expect(children.count()).to.equal 3

  it 'clears all items', ->
    children.clear()
    expect(children.count()).to.equal 0
    expect(parent.refs()).to.eql []
    expect(children.isEmpty()).to.equal true

  it 'saves the clear operation (once)', ->
    children.clear()
    doc = TestModels.findOne(parent.id)
    expect(doc.refs).to.eql []

  it 'does not save the clear operation', ->
    children.clear(save:false)
    doc = TestModels.findOne(parent.id)
    expect(doc.refs.length).to.eql 3


describe 'RefsCollection: toModels', ->
  foo1 = null
  foo2 = null
  foo3 = null

  beforeEach ->
    initStubs()
    foo1 = new RefModel()
    foo2 = new RefModel()
    foo3 = new RefModel()
    children.add([ foo1, foo2, foo3 ])

  it 'returns the set of models', ->
    models = children.toModels()
    expect(models.length).to.equal 3
    expect(models[0].id).to.equal foo1.id
    expect(models[1].id).to.equal foo2.id
    expect(models[2].id).to.equal foo3.id

  it 'return no model when empty', ->
    children.clear()
    models = children.toModels()
    expect(models.length).to.equal 0

  it 'returns no models when factory method not provided', ->
    children = new Data.ModelRefsCollection( parent, 'refs', null )
    models = children.toModels()
    expect(models.length).to.equal 0


describe 'RefsCollection: contains', ->
  beforeEach -> initStubs()

  it 'returns true from [contains()] when the model is present', ->
    foo = new RefModel()
    children.add(foo)
    expect(children.contains(foo)).to.equal true
    expect(children.contains(foo.id)).to.equal true

  it 'returns false from [contains()] when the model is present', ->
    foo = new RefModel()
    expect(children.contains(foo)).to.equal false
    expect(children.contains()).to.equal false
    expect(children.contains('blah')).to.equal false

describe 'RefsCollection: each', ->
  it 'enumerates each item in the collection', ->
    foo1 = new RefModel()
    foo2 = new RefModel()
    children.add([ foo1, foo2 ])
    items = []
    children.each (item) -> items.push(item)
    expect(items.length).to.equal 2
    expect(items[0]._doc).to.eql foo1._doc
    expect(items[1]._doc).to.eql foo2._doc


