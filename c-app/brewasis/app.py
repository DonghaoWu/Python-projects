#!/usr/bin/env python3

from flask import Flask, request, redirect, url_for, render_template
import pandas as pd
import numpy as np

from brewasisdb import get_data

app = Flask(__name__)

# HTML template data
craft_temp = '''
    <table id="table"> <tr> <td style = "width:220px">%s</td> <td style="width:45px">%s</td>
    <td style="width:50px">%s</td> <td style="width:50px">%s</td><td style="width:50px">%s</td> \
    <td style="width:50px">%s</td><td style="width:50px">%s</td>
    <td style="width:50px">%s</td><td style="width:50px">%s</td><td style="width:50px">%s</td> \
    <td style="width:50px">%s</td><td>%s</td></tr> </table>
'''

labels_top = [
    '2017', '2016', '2015', '2014',
    '2013', '2012', '2011', '2010',
    '2009', '2008'
]

@app.route("/top")
def topten():
  query_top = "select * \
                        from craft \
                        order by nullif((barrels2017 + barrels2016 + barrels2015 + barrels2014 + \
                        barrels2013), 'NaN') desc nulls last\
                        limit 10"
  values_top = []
  label_company = []
  for item in get_data(query_top):
      label_company.append(item[:1])
      values_top.append(item[2:])
  return render_template('chart_top.html', title='Top Five Company', labels=labels_top, \
    values=values_top, label_company=label_company)

@app.route("/company", methods=['GET', 'POST'])
def company():
  company = 'Boston Beer Co'
  if request.method == 'POST':
      company = request.form.get('company')
  query_company = "select * from craft where company = '%s' limit 1" % (company)
  values_company = []
  label_company = []
  for item in get_data(query_company):
    label_company.append(item[:1])
    values_company.append(item[2:])
  company_data = ""
  for item in get_data("select company from craft"):
      company_data = company_data + "<option value = '%s'>%s</option>" % (item[0], item[0])
  return render_template('chart_show.html', title='Company', labels=labels_top, \
    values=values_company, label_company=label_company, company_data = company_data)

@app.route("/craft", methods=['GET'])
def craft_get():
  query_craft = "select * \
                        from craft \
                        order by nullif((barrels2017 + barrels2016 + barrels2015 + \
                        barrels2014 + barrels2013), 'NaN') desc nulls last"
  craft_data = "".join(craft_temp % (company, state, barrels2017, barrels2016, barrels2015, \
    barrels2014, barrels2013, barrels2012, barrels2011, barrels2010, barrels2009, barrels2008) \
    for company, state, barrels2017, barrels2016, barrels2015, barrels2014, barrels2013, barrels2012,\
    barrels2011, barrels2010, barrels2009, barrels2008 in get_data(query_craft))
  return render_template("craft.html", craft_data = craft_data)

@app.route('/')
def main():
	return render_template('index.html')

if __name__ == '__main__':
  app.run("0.0.0.0","6060")
