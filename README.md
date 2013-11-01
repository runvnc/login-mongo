Testing this still, but this part is more or less tested:

*Note:* This code is [ToffeeScript](https://github.com/jiangmiao/toffee-script), which is very similar to CoffeeScript, but as you can see has a nice alternative to callbacks.  

```coffee-script
users = require 'users'

app.post '/logintry', (req, res) ->
  success = users.checkPassword! req.body.username, req.body.password
  if success
    req.session.user = req.body.username
    res.redirect '/app'
  else
    req.session.user = undefined
    res.redirect '/login.html'

app.post '/createuser', (req, res) ->
  e, success = users.add! req.body.email, req.body.username, req.body.password
  if not e?
    error = undefined
  else
    error = { message: e.message }
  res.end JSON.stringify { error, success }


```

By default it will send an email with postfix to the user with their password.  See `src/users.coffee`.


The equivalent to `/logintry` above in plain CoffeeScript:

```coffee-script
app.post '/logintry', (req, res) ->
  users.checkPassword req.body.username, req.body.password, (success) ->
    if success
    #...
```

