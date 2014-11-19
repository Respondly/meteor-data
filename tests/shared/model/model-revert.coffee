

class MySchema extends Data.Schema
  constructor: -> super
    foo: 123
    bar: 'abc'
    nothing: undefined


class Stub extends Data.Model
  constructor: (doc) ->
    super doc, MySchema



describe '[revertChanges] method', ->
  stub = null
  beforeEach -> stub = new Stub()

  it 'reverts a changes back to [null] changes', ->
    stub.foo('a')
    stub.bar('b')
    changes = stub.changes()
    expect(changes).not.to.equal null
    stub.revertChanges()


  it 'returns the change-set in the the state it was prior to the revert', ->
    stub.foo('a')
    result = stub.revertChanges()
    expect(result.foo.to).to.equal 'a'
    expect(result.foo.from).to.equal 123
    expect(stub.changes()).to.equal null


  it 'returns null when there are no changes to revert', ->
    expect(stub.revertChanges()).to.equal null


  it 'reverts to undefined', ->
    expect(stub.nothing()).to.equal undefined
    stub.nothing(123)
    expect(stub.nothing()).to.equal 123

    # debugger
    stub.revertChanges()

    console.log 'stub.nothing()', stub.nothing()
    console.log 'stub._doc', stub._doc

    expect(stub.nothing()).to.equal undefined





