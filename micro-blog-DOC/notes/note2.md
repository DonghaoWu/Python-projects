`specific type of client`: `the web browser`

`interact with a server that only returns HTML pages`?

`An API is a collection of HTTP routes that are designed as low-level entry points into the application. Instead of defining routes and view functions that return HTML to be consumed by web browsers, APIs allow the client to work directly with the application's resources, leaving the decision of how to present the information to the user entirely to the client.`

`The server only returns the requested information, leaving the client with the responsibility to present this information to the user.`(在这里指出的是API一般会返回一个JSON格式的response。)

`RESTful 特征`
Client-Server`（客户端-服务端 架构理念）`
The client-server principle is fairly straightforward, as it simply states that in a REST API the roles of the client and the server should be clearly differentiated. `In practice, this means that the client and the server are in separate processes that communicate over a transport, which in the majority of the cases is the HTTP protocol over a TCP network.`

Layered System `(多层间接系统)`

This is an important feature of REST, because being able to add intermediary nodes allows application architects to design large and complex networks that are able to satisfy a large volume of requests through the use of load balancers, caches, proxy servers, etc.

Cache（略过）

Stateless `(无状态无记忆化)`

The stateless principle is one of the two at the center of most debates between REST purists and pragmatists. It states that a REST API should not save any client state to be recalled every time a given client sends a request. What this means is that none of the mechanisms that are common in web development to "remember" users as they navigate through the pages of the application can be used. In a stateless API, every request needs to include the information that the server needs to identify and authenticate the client and to carry out the request. It also means that the server cannot store any data related to the client connection in a database or other form of storage.

If you are wondering why REST requires stateless servers, the main reason is that stateless servers are very easy to scale, all you need to do is run multiple instances of the server behind a load balancer. If the server stores client state things get more complicated, as you have to figure out how multiple servers can access and update that state, or alternatively ensure that a given client is always handled by the same server, something commonly referred to as sticky sessions.

Uniform Interface `(统一格式)`

REST uniform interface: unique resource identifiers, resource representations, self-descriptive messages, and hypermedia.


1. 建立 blueprint 模块, 注意最后引进的3大模块： users， errors， tokens
`Location:app/api/__init__.py`
```py
from flask import Blueprint

bp = Blueprint('api', __name__)

from app.api import users, errors, tokens
```


`The meat of the API is going to be stored in the app/api/users.py module.` The following table summarizes the routes that I'm going to implement:

HTTP Method	Resource URL	Notes
GET	/api/users/<id>	Return a user.
GET	/api/users	Return the collection of all users.
GET	/api/users/<id>/followers	Return the followers of this user.
GET	/api/users/<id>/followed	Return the users this user is following.
POST	/api/users	Register a new user account.
PUT	/api/users/<id>	Modify a user.
For now I'm going to create a skeleton module with placeholders for all these routes:


2. 建立 user 模块

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

3. 建立 error 模块

`Location:app/api/errors.py`

```py
def bad_request():
pass
```

4. 建立 token 模块

`Location:app/api/errors.py`

```py
def get_token():
pass

def revoke_token():
pass
```

5. 在主入口注册 api blueprint
The new API blueprint needs to be registered in the application factory function:

`Location:app/__init__.py`

```py
# ...

def create_app(config_class=Config):
app = Flask(__name__)

# ...

from app.api import bp as api_bp
app.register_blueprint(api_bp, url_prefix='/api')

# ...
```

`目前为止完成了入口， blueprint， 还有 3 大模块架构的定义 （users、errors、tokens）`

6. 用 JSON 方式承载数据
Representing Users as JSON Objects

`在 model 中添加新的 method，目的是为了实现把 user 转换成 JSON 形式`
`后面在使用过程中必须进行修改，因为暂时没有那么多的 attributes。`

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

def from_dict(self, data, new_user=False):
    for field in ['username', 'email', 'about_me']:
        if field in data:
            setattr(self, field, data[field])
    if new_user and 'password' in data:
        self.set_password(data['password'])
```


Finally, see how I implemented the hypermedia links. For the three links that point to other application routes I use url_for() to generate the URLs (which currently point to the placeholder view functions I defined in app/api/users.py). The avatar link is special because it is a Gravatar URL, external to the application. For this link I use the same avatar() method that I've used to render the avatars in web pages.

The to_dict() method converts a user object to a Python representation, which will then be converted to JSON. I also need look at the reverse direction, where the client passes a user representation in a request and the server needs to parse it and convert it to a User object. Here is the from_dict() method that achieves the conversion from a Python dictionary to a model:

7. 制作 errors 模块

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

def bad_request(message):
    return error_response(400, message)
```

注意这里的意思是取得 payload 后会使用一个很重要的函数 `jsonify` 把数据 json 格式化。

7. 制作 users 模块

A. 获得一个用户的资料
`Location:app/api/users.py`

```py
from flask import jsonify
from app.models import User

@bp.route('/users/<int:id>', methods=['GET'])
def get_user(id):
    return jsonify(User.query.get_or_404(id).to_dict())
```

`对比原本的route`

```py
@app.route('/user/<username>')
@login_required
def user(username):
    user = User.query.filter_by(username=username).first_or_404()
    posts = [
        {'author': user, 'body': 'Test post #1'},
        {'author': user, 'body': 'Test post #2'}
    ]
    return render_template('user.html', user=user, posts=posts)
```

`使用 extension 发出 request， 相当于 postman`
To test this new route, I'm going to install HTTPie, a command-line HTTP client written in Python that makes it easy to send API requests:

```bash
(venv) $ pip install httpie
```

```bash
(venv) $ http GET http://localhost:5000/api/users/1
```

B. 创建一个用户

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

`对比原本的route`

```py
@app.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, email=form.email.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('login'))
    return render_template('register.html', title='Register', form=form)
```
`***********IMPORTANT`
This request is going to accept a user representation in JSON format from the client, provided in the request body. Flask provides the request.get_json() method to extract the JSON from the request and return it as a Python structure. This method returns None if JSON data isn't found in the request, so I can ensure that I always get a dictionary using the expression request.get_json() or {}.

Before I can use the data I need to ensure that I've got all the information, so I start by checking that the three mandatory fields are included. These are username, email and password. If any of those are missing, then I use the bad_request() helper function from the app/api/errors.py module to return an error to the client. In addition to that check, I need to make sure that the username and email fields are not already used by another user, so for that I try to load a user from the database by the username and emails provided, and if any of those return a valid user, I also return an error back to the client.

Once I've passed the data validation, I can easily create a user object and add it to the database. To create the user I rely on the from_dict() method in the User model. The new_user argument is set to True, so that it also accepts the password field which is normally not part of the user representation.

The response that I return for this request is going to be the representation of the new user, so to_dict() generates that payload. The status code for a POST request that creates a resource should be 201, the code that is used when a new entity has been created. Also, the HTTP protocol requires that a 201 response includes a Location header that is set to the URL of the new resource.

`测试：`
```bash
(venv) $ http POST http://localhost:5000/api/users username=alice password=dog \
    email=alice@example.com "about_me=Hello, my name is Alice!"
```

C. 编辑一个用户

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

对比旧版：

```py
@app.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm(current_user.username)
    if form.validate_on_submit():
        current_user.username = form.username.data
        current_user.about_me = form.about_me.data
        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('edit_profile'))
    elif request.method == 'GET':
        form.username.data = current_user.username
        form.about_me.data = current_user.about_me
    return render_template('edit_profile.html', title='Edit Profile', form=form)
```

For this request I receive a user id as a dynamic part of the URL, so I can load the designated user and return a 404 error if it is not found. Note that there is no authentication yet, so for now the API is going to allow users to make changes to the accounts of any other users. This is going to be addressed later when authentication is added. `未有权限限制。`

Like in the case of a new user, I need to validate that the username and email fields provided by the client do not collide with other users before I can use them, but in this case the validation is a bit more tricky. First of all, these fields are optional in this request, so I need to check that a field is present. The second complication is that the client may be providing the same value, so before I check if the username or email are taken I need to make sure they are different than the current ones. If any of these validation checks fail, then I return a 400 error back to the client, as before.

Once the data has been validated, I can use the from_dict() method of the User model to import all the data provided by the client, and then commit the change to the database. The response from this request returns the updated user representation to the user, with a default 200 status code.

test：
```bash
(venv) $ http PUT http://localhost:5000/api/users/2 "about_me=Hi, I am Miguel"
```

`8. 制作 tokens 模块 (难点)`

A. 添加 token attribute 进 User model

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

B. 更新数据库架构
Because I have made changes to the database, I need to generate a new database migration and then upgrade the database with it:

```bash
(venv) $ flask db migrate -m "user tokens"
(venv) $ flask db upgrade
```

When you write an API you have to consider that your clients are not always going to be web browsers connected to the web application. The real power of APIs comes when standalone clients such as smartphone apps, or even browser-based single page applications can have access to backend services. When these specialized clients need to access API services, they begin by requesting a token, which is the counterpart to the login form in the traditional web application.

C. 使用新的 extension

```bash
(venv) $ pip install flask-httpauth
```

Flask-HTTPAuth supports a few different authentication mechanisms, all API friendly. To begin, I'm going to use HTTP Basic Authentication, in which the client sends the user credentials in a standard Authorization HTTP Header. To integrate with Flask-HTTPAuth, the application needs to provide two functions: one that defines the logic to check the username and password provided by the user, and another that returns the error response in the case of an authentication failure. `These functions are registered with Flask-HTTPAuth through decorators, and then are automatically called by the extension as needed during the authentication flow. `

D. 应用新 extension

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

The HTTPBasicAuth class from Flask-HTTPAuth is the one that implements the basic authentication flow. The two required functions are configured through the verify_password and error_handler decorators respectively.

The verification function receives the username and password that the client provided and returns True if the credentials are valid or False if not. To check the password I rely on the check_password() method of the User class, which is also used by Flask-Login during authentication for the web application. I save the authenticated user in g.current_user, so that I can then access it from the API view functions.

E. 添加 token 文件, 生成 token

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

This view function is decorated with the @basic_auth.login_required decorator from the HTTPBasicAuth instance, `which will instruct Flask-HTTPAuth to verify authentication (through the verification function I defined above) and only allow the function to run when the provided credentials are valid.` The implementation of this view function relies on the get_token() method of the user model to produce the token. A database commit is issued after the token is generated to ensure that the token and its expiration are written back to the database.

test：
```bash
(venv) $ http POST http://localhost:5000/api/tokens
```

```bash
(venv) $ http --auth <username>:<password> POST http://localhost:5000/api/tokens
```

Now the status code is 200, which is the code for a successful request, and the payload includes a newly generated token for the user. Note that when you send this request you will need to replace <username>:<password> with your own credentials. The username and password need to be provided with a colon as separator.

F. 验证 token, 定义验证函数。

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

G. 应用验证函数。

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

H. 注销 token

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