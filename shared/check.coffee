match = Data.match


###
Peforms a parameter check to match a model's { to | from } change-set.
For example:

    Meteor.methods
      'server/method': (changes) ->
        APP.core.check.changes myChanges,
              name: String
              startedAt: Date
              isActive: Boolean

@param param: The parameter value to check.
@param fields: An object containing the possible fields: { param:type }
###
Data.check.changes = (param, fields = {}) -> check(param, APP.core.match.changes(fields))



# MATCH HELPERS --------------------------------------------------------------------------



###
A match for a model's { to | from } change.
###
match.change = (type) ->
  if Object.isArray(type?.choices)
    # A [OneOf] object was passed.  Ensure it has <undefined> and <null>.
    type.choices.add(null)
    type.choices.add(undefined)
    oneOf = type

  else
    oneOf = Match.OneOf(undefined, null, type)

  oneOf = Match.Optional(oneOf)
  Match.Optional(from:oneOf, to:oneOf)



###
A match object for a set of model changes.
@param fields: An object containing the possible fields: { param:type }
###
match.changes = (fields = {}) ->
  matchChanges = (value) -> Match.Optional(Match.OneOf(null, undefined, value))

  for own key, type of fields
    # Standard property.
    fields[key] = match.change(type)

    if Object.isObject(type) # Simple object only (ie. not a dervied Meteor object like [OneOf]).
      # Sub-model.
      subModelChanges = match.changes(type) # <== RECURSION.
      fields[key] = matchChanges(subModelChanges)
    else
      # Standard property.
      fields[key] = match.change(type)

  matchChanges(fields)










