#= require ./schema
Schema = Data.Schema



###
The common date fields applied to objects.
###
Schema.dateFields =
  createdAt:  # The date the model was created.
    default:  undefined
    type:     Date

  updatedAt:  # The date the model was last updated in the DB.
    default:  undefined
    type:     Date






