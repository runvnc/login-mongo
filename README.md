Testing this still, but this part is more or less tested.

Usage example: 

```coffeescript

users = require 'users'

app.post '/logintry', (req, res) ->
  users.checkPassword req.body.username, req.body.password, (success) ->
    if success
      req.session.user = req.body.username
      res.redirect '/app'
    else
      req.session.user = undefined
      res.redirect '/login.html'

app.post '/createuser', (req, res) ->
  users.add req.body.email, req.body.username, req.body.password, (e, success) ->
    if not e?
      error = undefined
    else
      error = { message: e.message }
    res.end JSON.stringify { error, success }


```

By default it will send an email with postfix to the user with their password.  See `src/users.coffee`.


