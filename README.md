[Tiny Villages: Horizontally Scaling Society](http://runvnc.github.io/tinyvillage)

# login-mongo

A MongoDB back-end for creating users, checking passwords, updating passwords, and resetting passwords.  Optionally sends emails with templates you can specify.

`npm install login-mongo`

## Example (Express) creating a user: 
```javascript
var users = require('login-mongo'); // I like to just refer to it as 'users'

app.post('/createuser', function(req, res) {
  users.add(req.body.email, req.body.user, req.body.pass, function(err, success) {
    return res.end(JSON.stringify({
      error: err,
      success: success
    }));
  });
});
```

By default after adding a user, it will send an email (using sendmail) to the user.

## Example of logging in:
```javascript
app.post('/logintry', function(req, res) {
  users.checkPassword(req.body.user, req.body.pass, function(success) {
    if (success) {
      req.session.user = req.body.user;
      return res.redirect('/app');
    } else {
      req.session.user = void 0;
      return res.redirect('/login.html');
    }
  });
});

```

# Configuration

## config(options);

You do not *need* to call `users.config()`.  If you don't call it, these are the defaults:

```javascript
opts = {
  connect: 'mongo://localhost:27017/users',
  iterations: 10,  //number of rounds used in generating salt
  mail: {
    from: 'root',
    subjectadd: 'User account created',
    bodyadd: "Username: {{name}}",
    bodyreset: "Username: {{name}}",
    subjectreset: 'Password reset',
    mailer: 'sendmail'
  },
  collection: 'users',
  sendEmails: true
};
```

You can override just a few of the parameters, or all of them.  For example:

```javascript
users.config({ sendEmails: false, connect: 'mongo://localhost:27017/mydatabase' });
```

sets it up to use `mydatabase` instead of the default `users` database and prevents the emails.

If you want to use your own `nodemailer` transport for sending mail instead of `sendmail`, pass that as the `mail.mailer` option.  See the docs for `nodemailer`.

# Methods

## config(options)
  
## checkExists(email, function(err, exists){})

## addNoEmail(email, name, pass, function(){})

## add(email, name, pass, function(err, success){})

## resetPassword(name, function(tempPass){})

Note: `resetPassword` returns the new password which is _temporary_ and should be changed by the user.

## updatePassword(username, oldpass, newpass, function(success){})

## checkPassword(username, pass, function(success){})

See `src/users.coffee`.


