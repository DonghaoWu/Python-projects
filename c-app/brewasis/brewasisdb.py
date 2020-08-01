# "Database code"

import os
import psycopg2

DATABASE_URL = 'brewasis'

def get_data(query):
  """Return data from the database."""
  db = psycopg2.connect(database=DATABASE_URL)
  c = db.cursor()
  c.execute(query)
  return c.fetchall()
  db.close()
