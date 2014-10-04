describe 'core.Schema (Types)', ->
  Schema = Data.Schema
  Model  = Data.Model

  DateModel   = null
  DateSchema  = null
  now         = null

  beforeEach ->
    now = Date.create()

    class DateSchema extends Schema
      constructor: -> super
        created:
          default:  null
          type:     Date

        defaultNow:
          default:  -> now
          type:     Date

        simpleDate:
          type:     Date


    DateSchema.init()

    class DateModel extends Model
      constructor: (doc) -> super doc, DateSchema



  it 'stores [Date] type on field', ->
    expect(DateSchema.fields.created.type).to.equal Date

  it 'retrieves default value as [null]', ->
    model = new DateModel()
    expect(model.created()).to.equal null

  it 'retrieves default value from function', ->
    model = new DateModel()
    expect(model.defaultNow()).to.be.instanceof Date
    expect(model.defaultNow()).to.eql now

  it 'retrieves a [Date] value', ->
    model = new DateModel()
    date  = Date.create()
    model.created date.toString()
    expect(model.created()).to.be.instanceof Date
    expect(model.created().toString()).to.eql date.toString()


  it 'stores [Date] values as numbers', ->
    model = new DateModel()
    date = new Date()
    model.created(date)
    expect(model._doc.created).to.equal date.getTime()
    expect(Object.isNumber(model._doc.created)).to.equal true
    expect(Object.isDate(model.created())).to.equal true

  it 'stores a number (getTime) value', ->
    model = new DateModel()
    date = new Date()
    model.created(date.getTime())
    expect(Object.isNumber(model._doc.created)).to.equal true
    expect(model._doc.created).to.equal date.getTime()

  it 'does not overwrite existing [Date]', ->
    tomorrow  = Date.create('tomorrow')
    model     = new DateModel { defaultNow:tomorrow }
    expect(model.defaultNow()).to.equal tomorrow

  it 'does not convert <null> into a [Date]', ->
    model = new DateModel()
    model.created(Date.create())
    model.created(null)
    expect(model.created()).to.equal null

    model.created.delete()
    expect(model.created()).to.equal null # NB: Null is the 'default' value.

  it 'does not convert <undefined> into a [Date]', ->
    model = new DateModel()
    model.simpleDate(Date.create())
    model.simpleDate.delete()
    expect(model.simpleDate()).to.equal undefined





