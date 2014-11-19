

class StubSchema extends Data.Schema
  constructor: -> super
    foo:
      default: 123
      field: 'custom.path'

    text: 'abc'
    myUndefined: undefined
    myNull: null



class Stub extends Data.Model
  constructor: (doc) ->
    super doc, StubSchema



describe 'Model [changes] method', ->
  stub = null
  beforeEach -> stub = new Stub()

  it 'has no changes by default', ->
    expect(stub.changes()).to.equal null

  it 'stores changed [to] values', ->
    stub.foo 'my-foo'
    stub.text 'my-text'
    expect(stub.changes().foo.to).to.equal 'my-foo'
    expect(stub.changes().text.to).to.equal 'my-text'

  it 'stores changed [from] value', ->
    expect(stub.foo()).to.equal 123
    stub.foo 'a'
    stub.foo 'b' # Ensure that multile changes do not alter the original changed-[from] value.
    expect(stub.changes().foo.to).to.equal 'b'
    expect(stub.changes().foo.from).to.equal 123

  it 'reports a change when storing arrays of objects', ->
    value1 = [ { email: 'favstar_bot26@favstar.fm', name: null } ]
    value2 = [ { email: 'favstar_bot26@favstar.fm', name: 'favstar_bot26' } ]

    stub.foo(value1)
    stub.changes(clear:true)

    stub.foo(value2)
    expect(stub.changes().foo.from).to.eql value1
    expect(stub.changes().foo.to).to.eql value2


  it 'stores last value', ->
    stub.foo 1
    stub.foo 2
    expect(stub.changes().foo.to).to.equal 2

  it 'stores null (as the changed value)', ->
    stub.foo 1
    stub.foo null
    expect(stub.changes().foo.to).to.equal null


  it 'does not store a change if the value is the same', ->
    expect(stub.foo()).to.equal 123
    stub.foo 123 # Write the current value to the model.
    expect(stub.changes()).to.be.equal null

  it 'removes the changed value when set back to original', ->
    expect(stub.foo()).to.equal 123
    stub.foo 'new-foo'
    stub.text 'new-text' # Include second property change so that we don't have the whole change object be returned as [undefined]

    expect(stub.changes().foo.to).to.equal 'new-foo'
    stub.foo 123 # Revert to the original value.
    expect(stub.changes().foo).to.equal undefined

  it 'clears all changes when set back to original values', ->
    expect(stub.foo()).to.equal 123
    expect(stub.myNull()).to.equal null

    stub.foo('new-foo')
    stub.myNull('yo')

    # Revert to the original value.
    stub.foo(123)
    stub.myNull(null)
    expect(stub.changes()).to.equal null


  it 'clear changes when property deleted to an [undefined] value', ->
    expect(stub.myUndefined()).to.equal undefined
    expect(stub.changes()).to.equal null

    stub.myUndefined('hello')
    expect(stub.changes).not.to.equal null

    stub.myUndefined.delete()
    expect(stub.changes()).to.equal null


# ----------------------------------------------------------------------


describe 'changes method options', ->
  stub = null
  beforeEach -> stub = new Stub()

  it 'clears changes', ->
    stub.foo(1)
    stub.changes(clear:true)
    expect(stub.changes()).to.equal null

  it 'returns the "changes" value from a write operation', ->
    result = stub.changes(key:'foo', value:456)
    expect(result.foo.to).to.equal 456
    expect(result.foo.from).to.equal 123

  it 'throws if both a <key> and a <delete> option are specified', ->
    fn = ->
      stub.changes(key:'foo', delete:'foo')
    expect(fn).to.throw()


# ----------------------------------------------------------------------


describe 'Model [changes] - reactivity', ->
  stub = null
  beforeEach -> stub = new Stub()

  it 'has reactive changes on Model (default of string)', (done) ->
    changes = undefined
    Deps.autorun -> changes = stub.changes()
    stub.foo('new-foo')
    Util.delay =>
      @try =>
        expect(changes.foo.to).to.equal 'new-foo'
      done()

  it 'has reactive changes on Model (default of string)', (done) ->
    changes = undefined
    Deps.autorun -> changes = stub.changes()
    stub.myUndefined('yo')
    Util.delay =>
      @try =>
        expect(changes.myUndefined.to).to.equal 'yo'
      done()


  it 'reactively resets changes to null when <prop>.delete() method is called', (done) ->
    changes = undefined
    Deps.autorun -> changes = stub.changes()
    stub.myUndefined('foo')
    Util.delay =>
      expect(changes.myUndefined.from).to.equal undefined
      expect(changes.myUndefined.to).to.equal 'foo'
      stub.myUndefined.delete()
      Util.delay =>
        @try =>
          expect(changes).to.equal null
        done()


  it 'reactively sets changed value to [undefined] when <prop>.delete() method is called', (done) ->
    changes = undefined
    stub.myUndefined('foo')
    stub.revertChanges()
    Deps.autorun -> changes = stub.changes()

    expect(changes).to.equal null
    stub.text('yo')
    stub.myUndefined('foo')

    Util.delay =>

      expect(changes.text.to).to.equal 'yo'
      expect(changes.myUndefined.to).to.equal 'foo'
      expect(changes.myUndefined.from).to.equal undefined

      stub.myUndefined.delete()

      Util.delay =>
        expect(changes.text.to).to.equal 'yo'
        expect(changes.myUndefined).to.equal undefined
        done()


# ----------------------------------------------------------------------


describe '[syncChanges] method', ->
  stub1 = null
  stub2 = null
  beforeEach ->
    stub1 = new Stub()
    stub2 = new Stub()

  it 'changes values', ->
    stub1.foo   'my-value1'
    stub1.text  'my-value2'
    expect(stub2.foo()).not.to.equal 'my-value1'
    expect(stub2.text()).not.to.equal 'my-value2'

    Data.Model.syncChanges( stub2, stub1.changes() )

    expect(stub2.foo()).to.equal 'my-value1'
    expect(stub2.text()).to.equal 'my-value2'


  it 'returns the changed field definitions', ->
    stub1.foo 'my-value1'
    stub1.text  'my-value2'

    fields = Data.Model.syncChanges( stub2, stub1.changes() )

    expect(fields.length).to.equal 2
    expect(fields[0].key).to.equal 'foo'
    expect(fields[1].key).to.equal 'text'
