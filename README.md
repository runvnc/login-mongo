# login-mongo

Create users, check password, reset password, with a Mongo backend.

## Example (Express) creating a user: 

```javascript

var users;

users = require('users');

app.post('/createuser', function(req, res) {
  users.add(req.body.email, req.body.username, req.body.password, function(e, success) {
    var error;
    if (!(e != null)) {
      error = void 0;
    } else {
      error = {
        message: e.message
      };
    }
    return res.end(JSON.stringify({
      error: error,
      success: success
    }));
  });
});
```

By default after adding a user, it will send an email (using sendmail) to the user with their password.  

## Example of logging in:

```javascript
app.post('/logintry', function(req, res) {
  users.checkPassword(req.body.username, req.body.password, function(success) {
    if (success) {
      req.session.user = req.body.username;
      return res.redirect('/app');
    } else {
      req.session.user = void 0;
      return res.redirect('/login.html');
    }
  });
});

```

# Configuration

## users.config(options);

You do not *need* to call `users.config`.  If you don't call it, these are the defaults:

var opts;

```javascript
opts = {
  connect: 'mongo://localhost:27017/users',
  mail: {
    from: 'root',
    subjectadd: 'User account created',
    bodyadd: "Username: {{name}} password: {{password}}",
    bodyreset: "Username: {{name}} password: {{password}}",
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

##config(options)
  
## checkExists(email, function(err, exists){})

## addNoEmail(email, name, pass, function(){})

## add(email, name, pass, function(err, success){})

## resetPassword(name, function(success){})

## updatePassword(username, oldpass, newpass, function(success){})

## checkPassword(username, pass, function(success){})

See `src/users.coffee`.


