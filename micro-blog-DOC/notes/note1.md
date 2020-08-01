 There is a module for view functions, another one for web forms, one for errors, one for emails, a directory for HTML templates, and so on. While this is a structure that makes sense for small projects, once a project starts to grow, it tends to make some of these modules really large and messy.

 A better solution would be to not use a global variable for the application, and instead use an application factory function to create the function at runtime. This would be a function that accepts a configuration object as an argument, and returns a Flask application instance, configured with those settings. If I could modify the application to work with an application factory function, then writing tests that require special configuration would become easy, because each test can create its own application.

 In this chapter I'm going to refactor the application to introduce blueprints for the three subsystems I have identified above, and an application factory function. Showing you the detailed list of changes is going to be impractical, because there are little changes in pretty much every file that is part of the application, so I'm going to discuss the steps that I took to do the refactoring, and you can then download the application with these changes made.

 Blueprints
In Flask, a blueprint is a logical structure that represents a subset of the application. A blueprint can include elements such as routes, view functions, forms, templates and static files. If you write your blueprint in a separate Python package, then you have a component that encapsulates the elements related to specific feature of the application.

The contents of a blueprint are initially in a dormant state. To associate these elements, the blueprint needs to be registered with the application. During the registration, all the elements that were added to the blueprint are passed on to the application. So you can think of a blueprint as a temporary storage for application functionality that helps in organizing your code.

app/
    errors/                             <-- blueprint package
        __init__.py                     <-- blueprint creation
        handlers.py                     <-- error handlers
    templates/
        errors/                         <-- error templates
            404.html
            500.html
    __init__.py                         <-- blueprint registration

In essence, what I did is move the app/errors.py module into app/errors/handlers.py and the two error templates into app/templates/errors, so that they are separated from the other templates. I also had to change the render_template() calls in both error handlers to use the new errors template sub-directory. After that I added the blueprint creation to the app/errors/__init__.py module, and the blueprint registration to app/__init__.py, after the application instance is created.

The creation of a blueprint is fairly similar to the creation of an application. This is done in the ___init__.py module of the blueprint package:

`Location: app/errors/__init__.py`

```py
from flask import Blueprint

bp = Blueprint('errors', __name__)

from app.errors import handlers
```

The Blueprint class takes the name of the blueprint, the name of the base module (typically set to __name__ like in the Flask application instance), and a few optional arguments, which in this case I do not need. After the blueprint object is created, I import the handlers.py module, so that the error handlers in it are registered with the blueprint. This import is at the bottom to avoid circular dependencies.

In the handlers.py module, instead of attaching the error handlers to the application with the @app.errorhandler decorator, I use the blueprint's @bp.app_errorhandler decorator. While both decorators achieve the same end result, the idea is to try to make the blueprint independent of the application so that it is more `portable`. I also need to modify the path to the two error templates to account for the new errors sub-directory where they were moved.

The final step to complete the refactoring of the error handlers is to register the blueprint with the application:

```py
app = Flask(__name__)

# ...

from app.errors import bp as errors_bp
app.register_blueprint(errors_bp)

# ...

from app import routes, models  # <-- remove errors from this import!
```

app/
    auth/                               <-- blueprint package
        __init__.py                     <-- blueprint creation
        email.py                        <-- authentication emails
        forms.py                        <-- authentication forms
        routes.py                       <-- authentication routes
    templates/
        auth/                           <-- blueprint templates
            login.html
            register.html
            reset_password_request.html
            reset_password.html
    __init__.py                         <-- blueprint registration

When defining routes in a blueprint, the @bp.route decorate is used instead of @app.route. There is also a required change in the syntax used in the url_for() to build URLs. For regular view functions attached directly to the application, the first argument to url_for() is the view function name. When a route is defined in a blueprint, this argument must include the blueprint name and the view function name, separated by a period. So for example, I had to replace all occurrences of url_for('login') with url_for('auth.login'), and same for the remaining view functions.

`Location: app/errors/__init__.py`
```py
# ...
from app.auth import bp as auth_bp
app.register_blueprint(auth_bp, url_prefix='/auth')
# ...
```

The register_blueprint() call in this case has an extra argument, url_prefix. This is entirely optional, but Flask gives you the option to attach a blueprint under a URL prefix, so any routes defined in the blueprint get this prefix in their URLs. In many cases this is useful as a sort of "namespacing" that keeps all the routes in the blueprint separated from other routes in the application or other blueprints. For authentication, I thought it was nice to have all the routes starting with /auth, so I added the prefix. So now the login URL is going to be http://localhost:5000/auth/login. Because I'm using url_for() to generate the URLs, all URLs will automatically incorporate the prefix.

Main Application Blueprint
The third blueprint contains the core application logic. Refactoring this blueprint requires the same process that I used with the previous two blueprints. I gave this blueprint the name main, so all url_for() calls that referenced view functions had to get a main. prefix. Given that this is the core functionality of the application, I decided to leave the templates in the same locations. This is not a problem because I have moved the templates from the other two blueprints into sub-directories.

`到此为止已经改造了3个文件夹部分`

The Application Factory Pattern
As I mentioned in the introduction to this chapter, having the application as a global variable introduces some complications, mainly in the form of limitations for some testing scenarios. Before I introduced blueprints, the application had to be a global variable, because all the view functions and error handlers needed to be decorated with decorators that come from app, such as @app.route. But now that all routes and error handlers were moved to blueprints, there are a lot less reasons to keep the application global.

`Location: app/__init__.py`

```py
# ...
db = SQLAlchemy()
migrate = Migrate()
login = LoginManager()
login.login_view = 'auth.login'
login.login_message = _l('Please log in to access this page.')
mail = Mail()
bootstrap = Bootstrap()
moment = Moment()
babel = Babel()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    login.init_app(app)
    mail.init_app(app)
    bootstrap.init_app(app)
    moment.init_app(app)
    babel.init_app(app)

    # ... no changes to blueprint registration

    if not app.debug and not app.testing:
        # ... no changes to logging setup

    return app
```

You have seen that most Flask extensions are initialized by creating an instance of the extension and passing the application as an argument. When the application does not exist as a global variable, there is an alternative mode in which extensions are initialized in two phases. The extension instance is first created in the global scope as before, but no arguments are passed to it. This creates an instance of the extension that is not attached to the application. At the time the application instance is created in the factory function, the init_app() method must be invoked on the extension instances to bind it to the now known application.

Other tasks performed during initialization remain the same, but are moved to the factory function instead of being in the global scope. This includes the registration of blueprints and logging configuration. 

So who calls the application factory function? The obvious place to use this function is the top-level microblog.py script, which is the only module in which the application now exists in the global scope. The other place is in tests.py, and I will discuss unit testing in more detail in the next section.

As I mentioned above, most references to app went away with the introduction of blueprints, but there were some still in the code that I had to address. For example, the app/models.py, app/translate.py, and app/main/routes.py modules all had references to app.config. Fortunately, the Flask developers tried to make it easy for view functions to access the application instance without having to import it like I have been doing until now. The current_app variable that Flask provides is a special "context" variable that Flask initializes with the application before it dispatches a request. You have already seen another context variable before, the g variable in which I'm storing the current locale. These two, along with Flask-Login's current_user and a few others you haven't seen yet, are somewhat "magical" variables, in that they work like global variables, but are only accessible during the handling of a request, and only in the thread that is handling it.

Replacing app with Flask's current_app variable eliminates the need of importing the application instance as a global variable. I was able to change all references to app.config with current_app.config without any difficulty through simple search and replace.

So now you can create a .env file with all the environment variables that your application needs. It is important that you do not add your .env file to source control. You do not want to have a file that contains passwords and other sensitive information included in your source code repository.

The .env file can be used for all the configuration-time variables, but it cannot be used for Flask's FLASK_APP and FLASK_DEBUG environment variables, because these are needed very early in the application bootstrap process, before the application instance and its configuration object exist.

The following example shows a .env file that defines a secret key, configures email to go out on a locally running mail server on port 25 and no authentication, sets up the Microsoft Translator API key, and leaves the database configuration to use the defaults:

```py
SECRET_KEY=a-really-long-and-unique-key-that-nobody-knows
MAIL_SERVER=localhost
MAIL_PORT=25
MS_TRANSLATOR_KEY=<your-translator-key-here>
```

Requirements File
At this point I have installed a fair number of packages in the Python virtual environment. If you ever need to regenerate your environment on another machine, you are going to have trouble remembering what packages you had to install, so the generally accepted practice is to write a requirements.txt file in the root folder of your project listing all the dependencies, along with their versions. Producing this list is actually easy:

```bash
(venv) $ pip freeze > requirements.txt
```

The pip freeze command will dump all the packages that are installed on your virtual environment in the correct format for the requirements.txt file. Now, if you need to create the same virtual environment on another machine, instead of installing packages one by one, you can run:

```bash
(venv) $ pip install -r requirements.txt
```