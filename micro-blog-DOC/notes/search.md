Support for full-text search is not standardized like relational databases are. There are several open-source full-text engines: Elasticsearch, Apache Solr, Whoosh, Xapian, Sphinx, etc. As if this isn't enough choice, there are several databases that also provide searching capabilities that are comparable to dedicated search engines like the ones I enumerated above. SQLite, MySQL and PostgreSQL all offer some support for searching text, and NoSQL databases such as MongoDB and CouchDB do too.

From the list of dedicated search engines, Elasticsearch is one that stands out to me as being fairly popular, in part due to its popularity as the "E" in the ELK stack for indexing logs, along with Logstash and Kibana. Using the searching capabilities of one of the relational databases could also be a good choice, but given the fact that SQLAlchemy does not support this functionality, I would have to handle the searching with raw SQL statements, or else find a package that provides high-level access to text searches while being able to coexist with SQLAlchemy.

Based on the above analysis, I'm going to use Elasticsearch, but I'm going to implement all the text indexing and searching functions in a way that is very easy to switch to another engine. That will allow you to replace my implementation with an alternative one based on a different engine just by rewriting a few functions in a single module.

There are several ways to install Elasticsearch, including one-click installers, zip file with the binaries that you need to install yourself, and even a Docker image. The documentation has an Installation page with detailed information on all these options. If you are using Linux, you will likely have a package available for your distribution. If you are using a Mac and have Homebrew installed, then you can simply run brew install elasticsearch.

Once you install Elasticsearch on your computer, you can verify that it is running by typing http://localhost:9200 in your browser's address bar, which should return some basic information about the service in JSON format.

Elasticsearch 是一个 search engine，需要独立安装（像 python一样）。另外安装之后还需要安装 extension：

```bash
(venv) $ brew install elasticsearch.
(venv) $ pip install elasticsearch
(venv) $ pip freeze > requirements.txt
```

- Elasticsearch Tutorial

To create a connection to Elasticsearch, create an instance of class Elasticsearch, passing a connection URL as an argument:

I'm going to start by showing you the basics of working with Elasticsearch from a Python shell. 

```bash
(venv) $ python

>>> from elasticsearch import Elasticsearch
>>> es = Elasticsearch('http://localhost:9200')
>>> es.index(index='my_index', id=1, body={'text': 'this is a test'})
>>> es.index(index='my_index', id=2, body={'text': 'a second test'})
>>> es.index(index='my_index', id=2, body={'text': 'a second test'})
>>> es.indices.delete('my_index')

```

Data in Elasticsearch is written to indexes. Unlike a relational database, the data is just a JSON object. The following example writes an object with a field called text to an index called my_index:

For each document stored, Elasticsearch takes a unique id and the JSON object with the data.

Let's store a second document on this index:

And now that there are two documents in this index, I can issue a free-form search. In this example, I'm going to search for this test:


The response from the es.search() call is a Python dictionary with the search results:

```py
{
    'took': 1,
    'timed_out': False,
    '_shards': {'total': 5, 'successful': 5, 'skipped': 0, 'failed': 0},
    'hits': {
        'total': 2, 
        'max_score': 0.5753642, 
        'hits': [
            {
                '_index': 'my_index',
                '_type': 'my_index',
                '_id': '1',
                '_score': 0.5753642,
                '_source': {'text': 'this is a test'}
            },
            {
                '_index': 'my_index',
                '_type': 'my_index',
                '_id': '2',
                '_score': 0.25316024,
                '_source': {'text': 'a second test'}
            }
        ]
    }
}
```

Here you can see that the search returned the two documents, each with an assigned score. The document with the highest score contains the two words I searched for, and the other document contains only one. You can see that even the best result does not have a great score, because the words do not exactly match the text.

Now this is the result if I search for the word second:

```py
>>> es.search(index='my_index', body={'query': {'match': {'text': 'second'}}})
{
    'took': 1,
    'timed_out': False,
    '_shards': {'total': 5, 'successful': 5, 'skipped': 0, 'failed': 0},
    'hits': {
        'total': 1,
        'max_score': 0.25316024,
        'hits': [
            {
                '_index': 'my_index',
                '_type': 'my_index',
                '_id': '2',
                '_score': 0.25316024,
                '_source': {'text': 'a second test'}
            }
        ]
    }
}
```

I still get a fairly low score because my search does not match the text in this document, but since only one of the two documents contains the word "second", the other document does not show up at all.

The Elasticsearch query object has more options, all well documented, and includes options such as pagination and sorting, just like relational databases.

Feel free to add more entries to this index and try different searches. When you are done experimenting, you can delete the index with the following command:


- Elasticsearch Configuration

`Location:./config.py`:

```py
class Config(object):
    # ...
    ELASTICSEARCH_URL = os.environ.get('ELASTICSEARCH_URL')
```

Like with many other configuration entries, the connection URL for Elasticsearch is going to be sourced from an environment variable. If the variable is not defined, I'm going to let the setting be set to None, and I'll use that as a signal to disable Elasticsearch. This is mainly for convenience, so that you are not forced to always have the Elasticsearch service up and running when you work on the application, and in particular when you run unit tests. So to make sure the service is used, I need to define the ELASTICSEARCH_URL environment variable, either directly in the terminal or by adding it to the` .env `file as follows:

```py
ELASTICSEARCH_URL=http://localhost:9200
```

Elasticsearch presents the challenge that it isn't wrapped by a Flask extension. I cannot create the Elasticsearch instance in the global scope like I did in the examples above because to initialize it I need access to app.config, which only becomes available after the create_app() function is invoked. So I decided to add a elasticsearch attribute to the app instance in the application factory function:

`Location:./app/__init__.py`:

```py
# ...
from elasticsearch import Elasticsearch

# ...

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # ...
    app.elasticsearch = Elasticsearch([app.config['ELASTICSEARCH_URL']]) \
        if app.config['ELASTICSEARCH_URL'] else None

    # ...
```

Adding a new attribute to the app instance may seem a little strange, but Python objects are not strict in their structure, new attributes can be added to them at any time. An alternative that you may also consider is to create a subclass of Flask (maybe call it Microblog), with the elasticsearch attribute defined in its __init__() function.

Note how I use a conditional expression to make the Elasticsearch instance None when a URL for the Elasticsearch service wasn't defined in the environment.

- A Full-Text Search Abstraction

As I said in the chapter's introduction, I want to make it easy to switch from Elasticsearch to other search engines, and I also don't want to code this feature specifically for searching blog posts, I prefer to design a solution that in the future I can easily extend to other models if I need to. For all these reasons, I decided to create an abstraction for the search functionality. The idea is to design the feature in generic terms, so I will not be assuming that the Post model is the only one that needs to be indexed, and I will also not be assuming that Elasticsearch is the index engine of choice.

The first thing that I need, is to somehow find a generic way to indicate which model and which field or fields in it are to be indexed. I'm going to say that any model that needs indexing needs to define a __searchable__ class attribute that lists the fields that need to be included in the index. For the Post model, these are the changes:

`Location:./app/models.py`:

```py
class Post(db.Model):
    __searchable__ = ['body']
    # ...
```

So here I'm saying that this model needs to have its body field indexed. But just to make sure this is perfectly clear, this __searchable__ attribute that I added is just a variable, it does not have any behavior associated with it. It will just help me write my indexing functions in a generic way.

I'm going to write all the code that interacts with the Elasticsearch index in a app/search.py module. The idea is to keep all the Elasticsearch code in this module. The rest of the application will use the functions in this new module to access the index and will not have direct access to Elasticsearch. This is important, because if one day I decided I don't like Elasticsearch anymore and want to switch to a different engine, all I need to do is rewrite the functions in this module, and the application will continue to work as before.

For this application, I decided that I need three supporting functions related to text indexing: I need to add entries to a full-text index, I need to remove entries from the index (assuming one day I will support deleting blog posts), and I need to execute a search query. Here is the app/search.py module that implements these three functions for Elasticsearch, using the functionality I showed you above from the Python console:

`Location:./app/search.py`:

```py
from flask import current_app

def add_to_index(index, model):
    if not current_app.elasticsearch:
        return
    payload = {}
    for field in model.__searchable__:
        payload[field] = getattr(model, field)
    current_app.elasticsearch.index(index=index, id=model.id, body=payload)

def remove_from_index(index, model):
    if not current_app.elasticsearch:
        return
    current_app.elasticsearch.delete(index=index, id=model.id)

def query_index(index, query, page, per_page):
    if not current_app.elasticsearch:
        return [], 0
    search = current_app.elasticsearch.search(
        index=index,
        body={'query': {'multi_match': {'query': query, 'fields': ['*']}},
              'from': (page - 1) * per_page, 'size': per_page})
    ids = [int(hit['_id']) for hit in search['hits']['hits']]
    return ids, search['hits']['total']['value']
```

These functions all start by checking if app.elasticsearch is None, and in that case return without doing anything. This is so that when the Elasticsearch server isn't configured, the application continues to run without the search capability and without giving any errors. This is just as a matter of convenience during development or when running unit tests.

The functions accept the index name as an argument. In all the calls I'm passing down to Elasticsearch, I'm using this name as the index name and also as the document type, as I did in the Python console examples.

The functions that add and remove entries from the index take the SQLAlchemy model as a second argument. The add_to_index() function uses the __searchable__ class variable I added to the model to build the document that is inserted into the index. If you recall, Elasticsearch documents also needed a unique identifier. For that I'm using the id field of the SQLAlchemy model, which is also conveniently unique. Using the same id value for SQLAlchemy and Elasticsearch is very useful when running the searches, as it allows me to link entries in the two databases. Something I did not mention above is that if you attempt to add an entry with an existing id, then Elasticsearch replaces the old entry with the new one, so add_to_index() can be used for new objects as well as for modified ones.

I did not show you the es.delete() function that I'm using in remove_from_index() before. This function deletes the document stored under the given id. Here is a good example of the convenience of using the same id to link entries in both databases.

The query_index() function takes the index name and a text to search for, along with pagination controls, so that search results can be paginated like Flask-SQLAlchemy results are. You have already seen an example usage of the es.search() function from the Python console. The call I'm issuing here is fairly similar, but instead of using a match query type, I decided to use multi_match, which can search across multiple fields. By passing a field name of *, I'm telling Elasticsearch to look in all the fields, so basically I'm searching the entire index. This is useful to make this function generic, since different models can have different field names in the index.

The body argument to es.search() includes pagination arguments in addition to the query itself. The from and size arguments control what subset of the entire result set needs to be returned. Elasticsearch does not provide a nice Pagination object like the one from Flask-SQLAlchemy, so I have to do the pagination math to calculate the from value.

The return statement in the query_index() function is somewhat complex. It returns two values: the first is a list of id elements for the search results, and the second is the total number of results. Both are obtained from the Python dictionary returned by the es.search() function. If you are not familiar with the expression that I'm using to obtain the list of IDs, this is called a list comprehension, and is a fantastic feature of the Python language that allows you to transform lists from one format to another. In this case I'm using the list comprehension to extract the id values from the much larger list of results provided by Elasticsearch.

```py
>>> from app.search import add_to_index, remove_from_index, query_index
>>> for post in Post.query.all():
...     add_to_index('posts', post)
>>> query_index('posts', 'one two three four five', 1, 100)
([15, 13, 12, 4, 11, 8, 14], 7)
>>> query_index('posts', 'one two three four five', 1, 3)
([15, 13, 12], 7)
>>> query_index('posts', 'one two three four five', 2, 3)
([4, 11, 8], 7)
>>> query_index('posts', 'one two three four five', 3, 3)
([14], 7)
```

The query that I issued returned seven results. When I asked for page 1 with 100 items per page I get all seven, but then the next three examples shows how I can paginate the results in a way that is very similar to what I did for Flask-SQLAlchemy, with the exception that the results come as a list of IDs instead of SQLAlchemy objects.

If you want to keep things clean, delete the posts index after you are doing experimenting with it:

```py
>>> app.elasticsearch.indices.delete('posts')
```

- Integrating Searches with SQLAlchemy

The solution that I showed you in the previous section is decent, but it still has a couple of problems. The most obvious problem is that results come as a list of numeric IDs. This is highly inconvenient, I need SQLAlchemy models so that I can pass them down to templates for rendering, and I need a way to replace that list of numbers with the corresponding models from the database. The second problem is that this solution requires the application to explicitly issue indexing calls as posts are added or removed, which is not terrible, but less than ideal, since a bug that causes a missed indexing call when making a change on the SQLAlchemy side is not going to be easily detected, the two databases will get out of sync more and more each time the bug occurs and you will probably not notice for a while. A better solution would be for these calls to be triggered automatically as changes are made on the SQLAlchemy database.

- Search Form

- Search View Function