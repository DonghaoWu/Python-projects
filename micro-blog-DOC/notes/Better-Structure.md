Flask is a framework that is designed to give you the option to organize your project in any way you want, and as part of that philosophy, it makes it possible to change or adapt the structure of the application as it becomes larger, or as your needs or level of experience change.

In this chapter I'm going to discuss some patterns that apply to large applications, and to demonstrate them I'm going to make some changes to the way my Microblog project is structured, with the goal of making the code more maintainable and better organized. 

One way to clearly see the problem is to consider how you would start a second project by reusing as much as you can from this one.

For example, the user authentication portion should work well in other applications, but if you wanted to use that code as it is, you would have to go into several modules and copy/paste the pertinent sections into new files in the new project. 

The blueprints feature of Flask helps achieve a more practical organization that makes it easier to reuse code.

Because the application is defined as a global variable, there is really no way to instantiate two applications that use different configuration variables. Another situation that is not ideal is that all the tests use the same application, so a test could be making changes to the application that affect another test that runs later. Ideally you want all tests to run on a pristine application instance.

A better solution would be to not use a global variable for the application, and instead use an application factory function to create the function at runtime. This would be a function that accepts a configuration object as an argument, and returns a Flask application instance, configured with those settings. If I could modify the application to work with an application factory function, then writing tests that require special configuration would become easy, because each test can create its own application.

In Flask, a blueprint is a logical structure that represents a subset of the application. A blueprint can include elements such as routes, view functions, forms, templates and static files. If you write your blueprint in a separate Python package, then you have a component that encapsulates the elements related to specific feature of the application.

The contents of a blueprint are initially in a dormant state. To associate these elements, the blueprint needs to be registered with the application. During the registration, all the elements that were added to the blueprint are passed on to the application. So you can think of a blueprint as a temporary storage for application functionality that helps in organizing your code.

I should note that Flask blueprints can be configured to have a separate directory for templates or static files. I have decided to move the templates into a sub-directory of the application's template directory so that all templates are in a single hierarchy, but if you prefer to have the templates that belong to a blueprint inside the blueprint package, that is supported. For example, if you add a template_folder='templates' argument to the Blueprint() constructor, you can then store the blueprint's templates in app/errors/templates.

The creation of a blueprint is fairly similar to the creation of an application. This is done in the ___init__.py module of the blueprint package:

app/
    errors/                             <-- blueprint package
        __init__.py                     <-- blueprint creation
        handlers.py                     <-- error handlers
    templates/
        errors/                         <-- error templates
            404.html
            500.html
    __init__.py                         <-- blueprint registration


`Location: ./app/errors/__init__.py`

```py
from flask import Blueprint

bp = Blueprint('errors', __name__)

from app.errors import handlers
```

The Blueprint class takes the name of the blueprint, the name of the base module (typically set to __name__ like in the Flask application instance), and a few optional arguments, which in this case I do not need. After the blueprint object is created, I import the handlers.py module, so that the error handlers in it are registered with the blueprint. This import is at the bottom to avoid circular dependencies.

In the handlers.py module, instead of attaching the error handlers to the application with the @app.errorhandler decorator, I use the blueprint's @bp.app_errorhandler decorator. While both decorators achieve the same end result, the idea is to try to make the blueprint independent of the application so that it is more portable. I also need to modify the path to the two error templates to account for the new errors sub-directory where they were moved.

The final step to complete the refactoring of the error handlers is to register the blueprint with the application:

`Location: ./app/__init__.py`

```py
app = Flask(__name__)

# ...

from app.errors import bp as errors_bp
app.register_blueprint(errors_bp)

# ...

from app import routes, models  # <-- remove errors from this import!
```

To register a blueprint, the register_blueprint() method of the Flask application instance is used. When a blueprint is registered, any view functions, templates, static files, error handlers, etc. are connected to the application. I put the import of the blueprint right above the app.register_blueprint() to avoid circular dependencies.


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


`Location: ./app/__init__.py`

```py
from app.auth import bp as auth_bp
app.register_blueprint(auth_bp, url_prefix='/auth')
```

The register_blueprint() call in this case has an extra argument, url_prefix. This is entirely optional, but Flask gives you the option to attach a blueprint under a URL prefix, so any routes defined in the blueprint get this prefix in their URLs. In many cases this is useful as a sort of "namespacing" that keeps all the routes in the blueprint separated from other routes in the application or other blueprints. For authentication, I thought it was nice to have all the routes starting with /auth, so I added the prefix. So now the login URL is going to be http://localhost:5000/auth/login. Because I'm using url_for() to generate the URLs, all URLs will automatically incorporate the prefix.

The third blueprint contains the core application logic. Refactoring this blueprint requires the same process that I used with the previous two blueprints. I gave this blueprint the name main, so all url_for() calls that referenced view functions had to get a main. prefix. Given that this is the core functionality of the application, I decided to leave the templates in the same locations. This is not a problem because I have moved the templates from the other two blueprints into sub-directories.

As I mentioned in the introduction to this chapter, having the application as a global variable introduces some complications, mainly in the form of limitations for some testing scenarios.

Before I introduced blueprints, the application had to be a global variable, because all the view functions and error handlers needed to be decorated with decorators that come from app, such as @app.route. But now that all routes and error handlers were moved to blueprints, there are a lot less reasons to keep the application global.

So what I'm going to do, is add a function called create_app() that constructs a Flask application instance, and eliminate the global variable.

You have seen that most Flask extensions are initialized by creating an instance of the extension and passing the application as an argument. When the application does not exist as a global variable, there is an alternative mode in which extensions are initialized in two phases. The extension instance is first created in the global scope as before, but no arguments are passed to it. This creates an instance of the extension that is not attached to the application. At the time the application instance is created in the factory function, the init_app() method must be invoked on the extension instances to bind it to the now known application.

Other tasks performed during initialization remain the same, but are moved to the factory function instead of being in the global scope. This includes the registration of blueprints and logging configuration. Note that I have added a not app.testing clause to the conditional that decides if email and file logging should be enabled or not, so that all this logging is skipped during unit tests. The app.testing flag is going to be True when running unit tests, due to the TESTING variable being set to True in the configuration.

So who calls the application factory function? The obvious place to use this function is the top-level microblog.py script, which is the only module in which the application now exists in the global scope. 

As I mentioned above, most references to app went away with the introduction of blueprints, but there were some still in the code that I had to address. For example, the app/models.py, app/translate.py, and app/main/routes.py modules all had references to app.config. Fortunately, the Flask developers tried to make it easy for view functions to access the application instance without having to import it like I have been doing until now. The current_app variable that Flask provides is a special "context" variable that Flask initializes with the application before it dispatches a request. You have already seen another context variable before, the g variable in which I'm storing the current locale. These two, along with Flask-Login's current_user and a few others you haven't seen yet, are somewhat "magical" variables, in that they work like global variables, but are only accessible during the handling of a request, and only in the thread that is handling it.

Replacing app with Flask's current_app variable eliminates the need of importing the application instance as a global variable. I was able to change all references to app.config with current_app.config without any difficulty through simple search and replace.

In the send_email() function, the application instance is passed as an argument to a background thread that will then deliver the email without blocking the main application. Using current_app directly in the send_async_email() function that runs as a background thread would not have worked, because current_app is a context-aware variable that is tied to the thread that is handling the client request. In a different thread, current_app would not have a value assigned. Passing current_app directly as an argument to the thread object would not have worked either, because current_app is really a proxy object that is dynamically mapped to the application instance. So passing the proxy object would be the same as using current_app directly in the thread. What I needed to do is access the real application instance that is stored inside the proxy object, and pass that as the app argument. The current_app._get_current_object() expression extracts the actual application instance from inside the proxy object, so that is what I passed to the thread as an argument.

Another module that was tricky was app/cli.py, which implements a few shortcut commands for managing language translations. The current_app variable does not work in this case because these commands are registered at start up, not during the handling of a request, which is the only time when current_app can be used. To remove the reference to app in this module, I resorted to another trick, which is to move these custom commands inside a register() function that takes the app instance as an argument:

Then I called this register() function from microblog.py. Here is the complete microblog.py after all the refactoring:

As I hinted in the beginning of this chapter, a lot of the work that I did so far had the goal of improving the unit testing workflow. When you are running unit tests you want to make sure the application is configured in a way that it does not interfere with your development resources, such as your database.

The current version of tests.py resorts to the trick of modifying the configuration after it was applied to the application instance, which is a dangerous practice as not all types of changes will work when done that late. What I want is to have a chance to specify my testing configuration before it gets added to the application.

The create_app() function now accepts a configuration class as an argument. By default, the Config class defined in config.py is used, but I can now create an application instance that uses different configuration simply by passing a new class to the factory function. Here is an example configuration class that would be suitable to use for my unit tests:

What I'm doing here is creating a subclass of the application's Config class, and overriding the SQLAlchemy configuration to use an in-memory SQLite database. I also added a TESTING attribute set to True, which I currently do not need, but could be useful if the application needs to determine if it is running under unit tests or not.

If you recall, my unit tests relied on the setUp() and tearDown() methods, invoked automatically by the unit testing framework to create and destroy an environment that is appropriate for each test to run. I can now use these two methods to create and destroy a brand new application for each test:

The new application will be stored in self.app, but creating an application isn't enough to make everything work. Consider the db.create_all() statement that creates the database tables. The db instance needs to know what the application instance is, because it needs to get the database URI from app.config, but when you are working with an application factory you are not really limited to a single application, there could be more than one created. So how does db know to use the self.app instance that I just created?

The answer is in the application context. Remember the current_app variable, which somehow acts as a proxy for the application when there is no global application to import? This variable looks for an active application context in the current thread, and if it finds one, it gets the application from it. If there is no context, then there is no way to know what application is active, so current_app raises an exception. Below you can see how this works in a Python console. This needs to be a console started by running python, because the flask shell command automatically activates an application context for convenience.

So that's the secret! Before invoking your view functions, Flask pushes an application context, which brings current_app and g to life. When the request is complete, the context is removed, along with these variables. For the db.create_all() call to work in the unit testing setUp() method, I pushed an application context for the application instance I just created, and in that way, db.create_all() can use current_app.config to know where is the database. Then in the tearDown() method I pop the context to reset everything to a clean state.

You should also know that the application context is one of two contexts that Flask uses. There is also a request context, which is more specific, as it applies to a request. When a request context is activated right before a request is handled, Flask's request and session variables become available, as well as Flask-Login's current_user.

As you have seen as I built this application, there are a number of configuration options that depend on having variables set up in your environment before you start the server. This includes your secret key, email server information, database URL, and Microsoft Translator API key. You'll probably agree with me that this is inconvenient, because each time you open a new terminal session those variables need to be set again.

A common pattern for applications that depend on lots of environment variables is to store these in a .env file in the root application directory. The application imports the variables in this file when it starts, and that way, there is no need to have all these variables manually set by you.

Since the config.py module is where I read all the environment variables, I'm going to import a .env file before the Config class is created, so that the variables are set when the class is constructed:

So now you can create a .env file with all the environment variables that your application needs. It is important that you do not add your .env file to source control. You do not want to have a file that contains passwords and other sensitive information included in your source code repository.

The .env file can be used for all the configuration-time variables, but it cannot be used for Flask's FLASK_APP and FLASK_DEBUG environment variables, because these are needed very early in the application bootstrap process, before the application instance and its configuration object exist.

The following example shows a .env file that defines a secret key, configures email to go out on a locally running mail server on port 25 and no authentication, sets up the Microsoft Translator API key, and leaves the database configuration to use the defaults:


At this point I have installed a fair number of packages in the Python virtual environment. If you ever need to regenerate your environment on another machine, you are going to have trouble remembering what packages you had to install, so the generally accepted practice is to write a requirements.txt file in the root folder of your project listing all the dependencies, along with their versions. Producing this list is actually easy:

```bash
(venv) $ pip freeze > requirements.txt
```

The pip freeze command will dump all the packages that are installed on your virtual environment in the correct format for the requirements.txt file. Now, if you need to create the same virtual environment on another machine, instead of installing packages one by one, you can run:

```bash
(venv) $ pip install -r requirements.txt
```

