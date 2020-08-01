It is pretty clear that the server must manage times that are consistent and independent of location. If this application grows to the point of needing several production servers in different regions around the world, I would not want each server to write timestamps to the database in different timezones, because that would make working with these times impossible. Since UTC is the most used uniform timezone and is supported in the datetime class, that is what I'm going to use.

While standardizing the timestamps to UTC makes a lot of sense from the server's perspective, this creates a usability problem for users. The goal of this chapter is to address this problem while keeping all the timestamps managed in the server in UTC.

The obvious solution to the problem is to convert all timestamps from the stored UTC units to the local time of each user. This allows the server to continue using UTC for consistency, while an on-the-fly conversion tailored to each user solves the usability problem. The tricky part of this solution is to know the location of each user.

Many websites have a configuration page where users can specify their timezone. This would require me to add a new page with a form in which I present users with a dropdown with the list of timezones. Users can be asked to enter their timezone when they access the site for the first time, as part of their registration.

While this is a decent solution that solves the problem, it is a bit odd to ask users to enter a piece of information that they have already configured in their operating system. It seems it would be more efficient if I could just grab the timezone setting from their computers.

Moment.js is a small open-source JavaScript library that takes date and time rendering to another level, as it provides every imaginable formatting option, and then some. And a while ago I created Flask-Moment, a small Flask extension that makes it very easy to incorporate moment.js into your application.

```bash
(venv) $ pip install flask-moment
```

This extension is added to a Flask application in the usual way:
`Location: ./app/__init__.py`

```py
# ...
from flask_moment import Moment

app = Flask(__name__)
# ...
moment = Moment(app)

```

Unlike other extensions, Flask-Moment works together with moment.js, so all templates of the application must include this library. To ensure that this library is always available, I'm going to add it in the base template. This can be done in two ways. The most direct way is to explicitly add a <script> tag that imports the library, but Flask-Moment makes it easier, by exposing a moment.include_moment() function that generates the <script> tag:

`Location: ./app/templates/base.html`

```html
...

{% block scripts %}
    {{ super() }}
    {{ moment.include_moment() }}
{% endblock %}
```

The scripts block that I added here is another block exported by Flask-Bootstrap's base template. This is the place where JavaScript imports are to be included. This block is different from previous ones in that it already comes with some content defined in the base template. All I want to do is add the moment.js library, without losing the base contents. And this is achieved with the super() statement, which preserves the content from the base template. If you define a block in your template without using super(), then any content defined for this block in the base template will be lost.

- Using Moment.js

Moment.js makes a moment class available to the browser. The first step to render a timestamp is to create an object of this class, passing the desired timestamp in ISO 8601 format. 

If you are not familiar with the ISO 8601 standard format for dates and times, the format is as follows: {{ year }}-{{ month }}-{{ day }}T{{ hour }}:{{ minute }}:{{ second }}{{ timezone }}. I already decided that I was only going to work with UTC timezones, so the last part is always going to be Z, which represents UTC in the ISO 8601 standard.

Let's look at the timestamp that appears in the profile page. The current user.html template lets Python generate a string representation of the time. I can now render this timestamp using Flask-Moment as follows:

`Location: app/templates/user.html`

```html
...
    {% if user.last_seen %}
    <p>Last seen on: {{ moment(user.last_seen).format('LLL') }}</p>
    {% endif %}
```

So as you can see, Flask-Moment uses a syntax that is similar to that of the JavaScript library, with one difference being that the argument to moment() is now a Python datetime object and not an ISO 8601 string. The moment() call issued from a template also automatically generates the required JavaScript code to insert the rendered timestamp in the proper place of the DOM.

The second place where I can take advantage of Flask-Moment and moment.js is in the _post.html sub-template, which is invoked from the index and user pages. In the current version of the template, each post preceded with a "username says:" line. Now I can add a timestamp rendered with fromNow():

`Location: app/templates/_post.html`

```html
...
    <a href="{{ url_for('user', username=post.author.username) }}">
        {{ post.author.username }}
    </a>
    said {{ moment(post.timestamp).fromNow() }}:
    <br>
    {{ post.body }}
```

Below you can see how both these timestamps look when rendered with Flask-Moment and moment.js:
