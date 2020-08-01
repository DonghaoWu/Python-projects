`为什么要使用API`
All the functionality that I built so far for this application is meant for one `specific type of client`: `the web browser`. But what about other types of clients? If I wanted to build an Android or iOS app, for example, I have two main ways to go about it. The easiest solution would be to build `a simple app` with just a web view component that fills the entire screen, where the Microblog website is loaded, but this would offer little benefit over opening the application in the device's web browser. A better solution (though much more laborious) would be to `build a native app`, but how can this app `interact with a server that only returns HTML pages`?

`目前所做定都是针对单一客户端：web browser，应用程序唯一能返回的都是 HTML 文件。`

`(重点章节************)`
This is the problem area where Application Programming Interfaces (or APIs) can help. `An API is a collection of HTTP routes that are designed as low-level entry points into the application. Instead of defining routes and view functions that return HTML to be consumed by web browsers, APIs allow the client to work directly with the application's resources, leaving the decision of how to present the information to the user entirely to the client.` For example, an API in Microblog could provide user and blog post information to the client, and it could also allow the user to edit an existing blog post, but `only at the data level`, without mixing this logic with HTML.

I'm talking about the few routes that return JSON, such as the /translate route defined in Chapter 14. This is a route that takes a text, source and destination languages, all given in JSON format in a POST request. The response to this request is the translation of that text, also in JSON format. `The server only returns the requested information, leaving the client with the responsibility to present this information to the user.`(在这里指出的是API一般会返回一个JSON格式的response。)

Client-Server`（客户端-服务端 架构理念）`
The client-server principle is fairly straightforward, as it simply states that in a REST API the roles of the client and the server should be clearly differentiated. `In practice, this means that the client and the server are in separate processes that communicate over a transport, which in the majority of the cases is the HTTP protocol over a TCP network.`

Layered System
The layered system principle says that when a client needs to communicate with a server, it may end up connected to an intermediary and not the actual server. The idea is that for the client, there should be absolutely no difference in the way it sends requests if not connected directly to the server, in fact, it may not even know if it is connected to the target server or not. Likewise, this principle states that a server may receive client requests from an intermediary and not the client directly, so it must never assume that the other side of the connection is the client.

This is an important feature of REST, because being able to add intermediary nodes allows application architects to design large and complex networks that are able to satisfy a large volume of requests through the use of load balancers, caches, proxy servers, etc.

Cache
For the purposes of an API, the target server needs to indicate through the use of cache controls if a response can be cached by intermediaries as it travels back to the client. Note that because for security reasons APIs deployed to production must use encryption, caching is usually not done in an intermediate node unless this node terminates the SSL connection, or performs decryption and re-encryption.

Stateless
The stateless principle is one of the two at the center of most debates between REST purists and pragmatists. It states that a REST API should not save any client state to be recalled every time a given client sends a request. What this means is that none of the mechanisms that are common in web development to "remember" users as they navigate through the pages of the application can be used. In a stateless API, every request needs to include the information that the server needs to identify and authenticate the client and to carry out the request. It also means that the server cannot store any data related to the client connection in a database or other form of storage.

If you are wondering why REST requires stateless servers, the main reason is that stateless servers are very easy to scale, all you need to do is run multiple instances of the server behind a load balancer. If the server stores client state things get more complicated, as you have to figure out how multiple servers can access and update that state, or alternatively ensure that a given client is always handled by the same server, something commonly referred to as sticky sessions.

If you consider again the /translate route discussed in the chapter's introduction, you'll realize that it cannot be considered RESTful, because the view function associated with that route relies on the @login_required decorator from Flask-Login, which in turn stores the logged in state of the user in the Flask user session.

Uniform Interface
The final, most important, most debated and most vaguely documented REST principle is the uniform interface. Dr. Fielding enumerates four distinguishing aspects of the REST uniform interface: unique resource identifiers, resource representations, self-descriptive messages, and hypermedia.

Unique resource identifiers are achieved by assigning a unique URL to each resource. For example, the URL associated with a given user can be /api/users/<user-id>, where <user-id> is the identifier assigned to the user in the database table's primary key. This is reasonably well implemented by most APIs.

The use of resource representations means that when the server and the client exchange information about a resource, they must use an agreed upon format. For most modern APIs, the JSON format is used to build resource representations. An API can choose to support multiple resource representation formats, and in that case the content negotiation options in the HTTP protocol are the mechanism by which the client and the server can agree on a format that both like.

Self-descriptive messages means that requests and responses exchanged between the clients and the server must include all the information that the other party needs. As a typical example, the HTTP request method is used to indicate what operation the client wants the server to execute. A GET request indicates that the client wants to retrieve information about a resource, a POST request indicates the client wants to create a new resource, PUT or PATCH requests define modifications to existing resources, and DELETE indicates a request to remove a resource. The target resource is indicated as the request URL, with additional information provided in HTTP headers, the query string portion of the URL or the request body.

The hypermedia requirement is the most polemic of the set, and one that few APIs implement, and those APIs that do implement it rarely do so in a way that satisfies REST purists. Since the resources in an application are all inter-related, this requirement asks that those relationships are included in the resource representations, so that clients can discover new resources by traversing relationships, pretty much in the same way you discover new pages in a web application by clicking on links that take you from one page to the next. The idea is that a client could enter an API without any previous knowledge about the resources in it, and learn about them simply by following hypermedia links. One of the aspects that complicate the implementation of this requirement is that unlike HTML and XML, the JSON format that is commonly used for resource representations in APIs does not define a standard way to include links, so you are forced to use a custom structure, or one of the proposed JSON extensions that try to address this gap.

I'm going to create a new blueprint that will contain all the API routes. So let's begin by creating the directory where this blueprint will live:

```bash
(venv) $ mkdir app/api
```

查看第15章。

`Location:app/api/__init__.py`
```py
from flask import Blueprint

bp = Blueprint('api', __name__)

from app.api import users, errors, tokens
```

For now I'm going to create a skeleton module with placeholders for all these routes:

`Location:app/api/users.py`
```py
from app.api import bp

@bp.route('/users/<int:id>', methods=['GET'])
def get_user(id):
pass

@bp.route('/users', methods=['GET'])
def get_users():
pass

@bp.route('/users/<int:id>/followers', methods=['GET'])
def get_followers(id):
pass

@bp.route('/users/<int:id>/followed', methods=['GET'])
def get_followed(id):
pass

@bp.route('/users', methods=['POST'])
def create_user():
pass

@bp.route('/users/<int:id>', methods=['PUT'])
def update_user(id):
pass
```

`Location:app/api/errors.py`

```py
def bad_request():
pass
```


`Location:app/api/errors.py`

```py
def get_token():
pass

def revoke_token():
pass
```

`Location:app/api/__init__.py`

```py
# ...

def create_app(config_class=Config):
app = Flask(__name__)

# ...

from app.api import bp as api_bp
app.register_blueprint(api_bp, url_prefix='/api')

# ...
```


```js
{
"id": 123,
"username": "susan",
"password": "my-password",
"email": "susan@example.com",
"last_seen": "2017-10-20T15:04:27Z",
"about_me": "Hello, my name is Susan!",
"post_count": 7,
"follower_count": 35,
"followed_count": 21,
"_links": {
    "self": "/api/users/123",
    "followers": "/api/users/123/followers",
    "followed": "/api/users/123/followed",
    "avatar": "https://www.gravatar.com/avatar/..."
}
}
```

One nice thing about the JSON format is that it always translates to a representation as a Python dictionary or list. The json package from the Python standard library takes care of converting the Python data structures to and from JSON. So to generate these representations, I'm going to add a method to the User model called to_dict(), which returns a Python dictionary:



`Location:app/models.py`

```py
from flask import url_for
# ...

class User(UserMixin, db.Model):
# ...

def to_dict(self, include_email=False):
    data = {
        'id': self.id,
        'username': self.username,
        'last_seen': self.last_seen.isoformat() + 'Z',
        'about_me': self.about_me,
        'post_count': self.posts.count(),
        'follower_count': self.followers.count(),
        'followed_count': self.followed.count(),
        '_links': {
            'self': url_for('api.get_user', id=self.id),
            'followers': url_for('api.get_followers', id=self.id),
            'followed': url_for('api.get_followed', id=self.id),
            'avatar': self.avatar(128)
        }
    }
    if include_email:
        data['email'] = self.email
    return data
```

This method should be mostly self-explanatory, the dictionary with the user representation I settled on is simply generated and returned. As I mentioned above, the email field needs special treatment, because I want to include the email only when users request their own data. So I'm using the include_email flag to determine if that field gets included in the representation or not.

Finally, see how I implemented the hypermedia links. For the three links that point to other application routes I use url_for() to generate the URLs (which currently point to the placeholder view functions I defined in app/api/users.py). The avatar link is special because it is a Gravatar URL, external to the application. For this link I use the same avatar() method that I've used to render the avatars in web pages.

The to_dict() method converts a user object to a Python representation, which will then be converted to JSON. I also need look at the reverse direction, where the client passes a user representation in a request and the server needs to parse it and convert it to a User object. Here is the from_dict() method that achieves the conversion from a Python dictionary to a model:


`Location:app/models.py`

```py
class User(UserMixin, db.Model):
# ...

def from_dict(self, data, new_user=False):
    for field in ['username', 'email', 'about_me']:
        if field in data:
            setattr(self, field, data[field])
    if new_user and 'password' in data:
        self.set_password(data['password'])
```

In this case I decided to use a loop to import any of the fields that the client can set, which are username, email and about_me. For each field I check if I there is a value provided in the data argument, and if there is I use Python's setattr() to set the new value in the corresponding attribute for the object.

The password field is treated as a special case, because it isn't a field in the object. The new_user argument determines if this is a new user registration, which means that a password is included. To set the password in the user model, I call the set_password() method, which creates the password hash.

Representing Collections of Users
In addition to working with single resource representations, this API is going to need a representation for a group of users. This is going to be the format used when the client requests the list of users or followers,`暂时省略`

Error Handling
When an API needs to return an error, it needs to be a "machine friendly" type of error, something that the client application can easily interpret. So in the same way I defined representations for my API resources in JSON, now I'm going to decide on a representation for API error messages.


`Location:app/api/errors.py`

```py
from flask import jsonify
from werkzeug.http import HTTP_STATUS_CODES

def error_response(status_code, message=None):
    payload = {'error': HTTP_STATUS_CODES.get(status_code, 'Unknown error')}
    if message:
        payload['message'] = message
    response = jsonify(payload)
    response.status_code = status_code
    return response
```

The most common error that the API is going to return is going to be the code 400, which is the error for "bad request". This is the error that is used when the client sends a request that has invalid data in it. To make it even easier to generate this error, I'm going to add a dedicated function for it that only requires the long descriptive message as an argument. This is the bad_request() placeholder that I added earlier:

`Location:app/api/errors.py`

```py
# ...

def bad_request(message):
    return error_response(400, message)
```

Retrieving a User
Let's start with the request to retrieve a single user, given by id:


`Location:app/api/users.py`
```py
from flask import jsonify
from app.models import User

@bp.route('/users/<int:id>', methods=['GET'])
def get_user(id):
    return jsonify(User.query.get_or_404(id).to_dict())
```

The to_dict() method I added to User is used to generate the dictionary with the resource representation for the selected user, and then Flask's jsonify() function converts that dictionary to JSON format to return to the client.

To test this new route, I'm going to install HTTPie, a command-line HTTP client written in Python that makes it easy to send API requests:

```bash
(venv) $ pip install httpie
```

test:

```bash
(venv) $ http GET http://localhost:5000/api/users/1
HTTP/1.0 200 OK
Content-Length: 457
Content-Type: application/json
Date: Mon, 27 Nov 2017 20:19:01 GMT
Server: Werkzeug/0.12.2 Python/3.6.3

{
    "_links": {
        "avatar": "https://www.gravatar.com/avatar/993c...2724?d=identicon&s=128",
        "followed": "/api/users/1/followed",
        "followers": "/api/users/1/followers",
        "self": "/api/users/1"
    },
    "about_me": "Hello! I'm the author of the Flask Mega-Tutorial.",
    "followed_count": 0,
    "follower_count": 1,
    "id": 1,
    "last_seen": "2017-11-26T07:40:52.942865Z",
    "post_count": 10,
    "username": "miguel"
}
```

Retrieving Collections of Users
To return the collection of all users, I can now rely on the to_collection_dict() method of PaginatedAPIMixin:

`Location:app/api/users.py`
```py
from flask import request

@bp.route('/users', methods=['GET'])
def get_users():
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 100)
    data = User.to_collection_dict(User.query, page, per_page, 'api.get_users')
    return jsonify(data)
```

test:
```bash
(venv) $ http GET http://localhost:5000/api/users
```

get all followers（省略）

Registering New Users

The POST request to the /users route is going to be used to register new user accounts. You can see the implementation of this route below:

`Location:app/api/users.py`

```py
from flask import url_for
from app import db
from app.api.errors import bad_request

@bp.route('/users', methods=['POST'])
def create_user():
    data = request.get_json() or {}
    if 'username' not in data or 'email' not in data or 'password' not in data:
        return bad_request('must include username, email and password fields')
    if User.query.filter_by(username=data['username']).first():
        return bad_request('please use a different username')
    if User.query.filter_by(email=data['email']).first():
        return bad_request('please use a different email address')
    user = User()
    user.from_dict(data, new_user=True)
    db.session.add(user)
    db.session.commit()
    response = jsonify(user.to_dict())
    response.status_code = 201
    response.headers['Location'] = url_for('api.get_user', id=user.id)
    return response
```

Once I've passed the data validation, I can easily create a user object and add it to the database. To create the user I rely on the from_dict() method in the User model. The new_user argument is set to True, so that it also accepts the password field which is normally not part of the user representation.

The response that I return for this request is going to be the representation of the new user, so to_dict() generates that payload. The status code for a POST request that creates a resource should be 201, the code that is used when a new entity has been created. Also, the HTTP protocol requires that a 201 response includes a Location header that is set to the URL of the new resource.

```bash
(venv) $ http POST http://localhost:5000/api/users username=alice password=dog \
    email=alice@example.com "about_me=Hello, my name is Alice!"
```

`Location:app/api/users.py`

```py
@bp.route('/users/<int:id>', methods=['PUT'])
def update_user(id):
    user = User.query.get_or_404(id)
    data = request.get_json() or {}
    if 'username' in data and data['username'] != user.username and \
            User.query.filter_by(username=data['username']).first():
        return bad_request('please use a different username')
    if 'email' in data and data['email'] != user.email and \
            User.query.filter_by(email=data['email']).first():
        return bad_request('please use a different email address')
    user.from_dict(data, new_user=False)
    db.session.commit()
    return jsonify(user.to_dict())
```

For this request I receive a user id as a dynamic part of the URL, so I can load the designated user and return a 404 error if it is not found. Note that there is no authentication yet, so for now the API is going to allow users to make changes to the accounts of any other users. This is going to be addressed later when authentication is added. `未有权限限制。`

Like in the case of a new user, I need to validate that the username and email fields provided by the client do not collide with other users before I can use them, but in this case the validation is a bit more tricky. First of all, these fields are optional in this request, so I need to check that a field is present. The second complication is that the client may be providing the same value, so before I check if the username or email are taken I need to make sure they are different than the current ones. If any of these validation checks fail, then I return a 400 error back to the client, as before.

Once the data has been validated, I can use the from_dict() method of the User model to import all the data provided by the client, and then commit the change to the database. The response from this request returns the updated user representation to the user, with a default 200 status code.

test：
```bash
(venv) $ http PUT http://localhost:5000/api/users/2 "about_me=Hi, I am Miguel"
```

API Authentication
The API endpoints I added in the previous section are currently open to any clients. Obviously they need to be available to registered users only, and to do that I need to add authentication and authorization, or "AuthN" and "AuthZ" for short. The idea is that requests sent by clients provide some sort of identification, so that the server knows what user the client is representing, and can verify if the requested action is allowed or not for that user.

The most obvious way to protect these API endpoints is to use the @login_required decorator from Flask-Login, but that approach has some problems. When the decorator detects a non-authenticated user, it redirects the user to a HTML login page. In an API there is no concept of HTML or login pages, if a client sends a request with invalid or missing credentials, the server has to refuse the request returning a 401 status code. The server can't assume that the API client is a web browser, or that it can handle redirects, or that it can render and process HTML login forms. When the API client receives the 401 status code, it knows that it needs to ask the user for credentials, but how it does that is really not the business of the server.

Tokens In the User Model
For the API authentication needs, I'm going to use a token authentication scheme. When a client wants to start interacting with the API, it needs to request a temporary token, authenticating with a username and password. The client can then send API requests passing the token as authentication, for as long as the token is valid. Once the token expires, a new token needs to be requested. To support user tokens, I'm going to expand the User

`Location:app/models.py`

```py
import base64
from datetime import datetime, timedelta
import os

class User(UserMixin, PaginatedAPIMixin, db.Model):
    # ...
    token = db.Column(db.String(32), index=True, unique=True)
    token_expiration = db.Column(db.DateTime)

    # ...

    def get_token(self, expires_in=3600):
        now = datetime.utcnow()
        if self.token and self.token_expiration > now + timedelta(seconds=60):
            return self.token
        self.token = base64.b64encode(os.urandom(24)).decode('utf-8')
        self.token_expiration = now + timedelta(seconds=expires_in)
        db.session.add(self)
        return self.token

    def revoke_token(self):
        self.token_expiration = datetime.utcnow() - timedelta(seconds=1)

    @staticmethod
    def check_token(token):
        user = User.query.filter_by(token=token).first()
        if user is None or user.token_expiration < datetime.utcnow():
            return None
        return user
```

With this change I'm adding a token attribute to the user model, and because I'm going to need to search the database by it I make it unique and indexed. I also added token_expiration, which has the date and time at which the token expires. This is so that a token does not remain valid for a long period of time, which can become a security risk.

I created three methods to work with these tokens. The get_token() method returns a token for the user. The token is generated as a random string that is encoded in base64 so that all the characters are in the readable range. Before a new token is created, this method checks if a currently assigned token has at least a minute left before expiration, and in that case the existing token is returned.

When working with tokens it is always good to have a strategy to revoke a token immediately, instead of only relying on the expiration date. This is a security best practice that is often overlooked. The revoke_token() method makes the token currently assigned to the user invalid, simply by setting the expiration date to one second before the current time.

The check_token() method is a static method that takes a token as input and returns the user this token belongs to as a response. If the token is invalid or expired, the method returns None.

Because I have made changes to the database, I need to generate a new database migration and then upgrade the database with it:

```bash
(venv) $ flask db migrate -m "user tokens"
(venv) $ flask db upgrade
```

When you write an API you have to consider that your clients are not always going to be web browsers connected to the web application. The real power of APIs comes when standalone clients such as smartphone apps, or even browser-based single page applications can have access to backend services. When these specialized clients need to access API services, they begin by requesting a token, which is the counterpart to the login form in the traditional web application.

```bash
(venv) $ pip install flask-httpauth
```

Flask-HTTPAuth supports a few different authentication mechanisms, all API friendly. To begin, I'm going to use HTTP Basic Authentication, in which the client sends the user credentials in a standard Authorization HTTP Header. To integrate with Flask-HTTPAuth, the application needs to provide two functions: one that defines the logic to check the username and password provided by the user, and another that returns the error response in the case of an authentication failure. `These functions are registered with Flask-HTTPAuth through decorators, and then are automatically called by the extension as needed during the authentication flow. `

`Location:app/api/auth.py`
```py
from flask import g
from flask_httpauth import HTTPBasicAuth
from app.models import User
from app.api.errors import error_response

basic_auth = HTTPBasicAuth()

@basic_auth.verify_password
def verify_password(username, password):
    user = User.query.filter_by(username=username).first()
    if user is None:
        return False
    g.current_user = user
    return user.check_password(password)

@basic_auth.error_handler
def basic_auth_error():
    return error_response(401)
```

The verification function receives the username and password that the client provided and returns True if the credentials are valid or False if not. To check the password I rely on the check_password() method of the User class, which is also used by Flask-Login during authentication for the web application. I save the authenticated user in g.current_user, so that I can then access it from the API view functions.

The error handler function simply returns a 401 error, generated by the error_response() function in app/api/errors.py. The 401 error is defined in the HTTP standard as the "Unauthorized" error. HTTP clients know that when they receive this error the request that they sent needs to be resent with valid credentials.


Now I have basic authentication support implemented, so I can add the token retrieval route that clients will invoke when they need a token:
`Location:app/api/tokens.py`

```py
from flask import jsonify, g
from app import db
from app.api import bp
from app.api.auth import basic_auth

@bp.route('/tokens', methods=['POST'])
@basic_auth.login_required
def get_token():
    token = g.current_user.get_token()
    db.session.commit()
    return jsonify({'token': token})
```

This view function is decorated with the @basic_auth.login_required decorator from the HTTPBasicAuth instance, which will instruct Flask-HTTPAuth to verify authentication (through the verification function I defined above) and only allow the function to run when the provided credentials are valid. The implementation of this view function relies on the get_token() method of the user model to produce the token. A database commit is issued after the token is generated to ensure that the token and its expiration are written back to the database.


test：
```bash
(venv) $ http POST http://localhost:5000/api/tokens
```

```bash
(venv) $ http --auth <username>:<password> POST http://localhost:5000/api/tokens
```

Now the status code is 200, which is the code for a successful request, and the payload includes a newly generated token for the user. Note that when you send this request you will need to replace <username>:<password> with your own credentials. The username and password need to be provided with a colon as separator.

Protecting API Routes with Tokens
The clients can now request a token to use with the API endpoints, so what's left is to add token verification to those endpoints. This is something that Flask-HTTPAuth can also handle for me. I need to create a second authentication instance based on the HTTPTokenAuth class, and provide a token verification callback:


`Location:app/api/auth.py`
```py
# ...
from flask_httpauth import HTTPTokenAuth

# ...
token_auth = HTTPTokenAuth()

# ...

@token_auth.verify_token
def verify_token(token):
    g.current_user = User.check_token(token) if token else None
    return g.current_user is not None

@token_auth.error_handler
def token_auth_error():
    return error_response(401)
```

When using token authentication, Flask-HTTPAuth uses a verify_token decorated function, but other than that, token authentication works in the same way as basic authentication. My token verification function uses User.check_token() to locate the user that owns the provided token. The function also handles the case of a missing token by setting the current user to None. The True or False return value determines if Flask-HTTPAuth allows the view function to run or not.

To protect API routes with tokens, the @token_auth.login_required decorator needs to be added:

`Location:app/api/users.py`

```py
from flask import g, abort
from app.api.auth import token_auth

@bp.route('/users/<int:id>', methods=['GET'])
@token_auth.login_required
def get_user(id):
    # ...

@bp.route('/users', methods=['GET'])
@token_auth.login_required
def get_users():
    # ...

@bp.route('/users/<int:id>/followers', methods=['GET'])
@token_auth.login_required
def get_followers(id):
    # ...

@bp.route('/users/<int:id>/followed', methods=['GET'])
@token_auth.login_required
def get_followed(id):
    # ...

@bp.route('/users', methods=['POST'])
def create_user():
    # ...

@bp.route('/users/<int:id>', methods=['PUT'])
@token_auth.login_required
def update_user(id):
    if g.current_user.id != id:
        abort(403)
    # ...
```

If you send a request to any of these endpoints as shown previously, you will get back a 401 error response. To gain access, you need to add the Authorization header, with a token that you received from a request to /api/tokens. Flask-HTTPAuth expects the token to be sent as a "bearer" token, which isn't directly supported by HTTPie. For basic authentication with username and password, HTTPie offers a --auth option, but for tokens the header needs to be explicitly provided. Here is the syntax to send the bearer token:

```bash
(venv) $ http GET http://localhost:5000/api/users/1 \
    "Authorization:Bearer pC1Nu9wwyNt8VCj1trWilFdFI276AcbS"
```

Revoking Tokens
The last token related feature that I'm going to implement is the token revocation, which you can see below:

`Location: app/api/tokens.py`

```py
from app.api.auth import token_auth

@bp.route('/tokens', methods=['DELETE'])
@token_auth.login_required
def revoke_token():
    g.current_user.revoke_token()
    db.session.commit()
    return '', 204
```

Clients can send a DELETE request to the /tokens URL to invalidate the token. The authentication for this route is token based, in fact the token sent in the Authorization header is the one being revoked. The revocation itself uses the helper method in the User class, which resets the expiration date on the token. The database session is committed so that this change is written to the database. The response from this request does not have a body, so I can return an empty string. A second value in the return statement sets the status code of the response to 204, which is the code to use for successful requests that have no response body.

```bash
(venv) $ http DELETE http://localhost:5000/api/tokens \
    Authorization:"Bearer pC1Nu9wwyNt8VCj1trWilFdFI276AcbS"
```

API Friendly Error Messages
What I want to do is modify the global application error handlers so that they use content negotiation to reply in HTML or JSON according to the client preferences. This can be done using the request.accept_mimetypes object from Flask:

`Location: app/errors/handlers.py`

```py
from flask import render_template, request
from app import db
from app.errors import bp
from app.api.errors import error_response as api_error_response

def wants_json_response():
    return request.accept_mimetypes['application/json'] >= \
        request.accept_mimetypes['text/html']

@bp.app_errorhandler(404)
def not_found_error(error):
    if wants_json_response():
        return api_error_response(404)
    return render_template('errors/404.html'), 404

@bp.app_errorhandler(500)
def internal_error(error):
    db.session.rollback()
    if wants_json_response():
        return api_error_response(500)
    return render_template('errors/500.html'), 500
```
The wants_json_response() helper function compares the preference for JSON or HTML selected by the client in their list of preferred formats. If JSON rates higher than HTML, then I return a JSON response. Otherwise I'll return the original HTML responses based on templates. For the JSON responses I'm going to import the error_response helper function from the API blueprint, but here I'm going to rename it to api_error_response() so that it is clear what it does and where it comes from.
