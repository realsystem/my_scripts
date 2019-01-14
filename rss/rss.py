import feedparser
import os
import errno
import hashlib
import sys
import smtplib
import datetime
import argparse
from email.mime.text import MIMEText


class CheckCL(object):
  def __init__(self):
    self._options = None

  @property
  def options(self):
    if self._options:
      return self._options
    parser = argparse.ArgumentParser(description='Check Craigslist for new posts')
    parser.add_argument('--query', '-q', required=True,
                        help='Query word to search on Craigslist')
    parser.add_argument('--pic', '-p', action='store_true',
                            help='Post has pictures')
    parser.add_argument('--maxprice', '-u',
                        help='Maximum price in search')
    parser.add_argument('--minprice', '-l',
                        help='Minimum price in search')
    parser.add_argument('--group', '-g',
                        help='Group for sale')
    parser.add_argument('--recepient', '-r', required=True,
                        help='Email to be used as recepient')
    parser.add_argument('--sender', '-s', required=True,
                        help='Email to be used as sender')
    parser.add_argument('--password', '-pwd', required=True,
                        help='Email password to be used as sender')
    parser.add_argument('--dbpath', '-d', default='/tmp/',
                        help='Path to store data about posts')
    self._options = parser.parse_args()

    return self._options

  @property
  def dbFileName(self):
    return 'rss.' + self.options.query.replace(' ', '-') + '.db'

  @property
  def dbFile(self):
    return self.options.dbpath + self.dbFileName

  def load_DB(self):
    records = set()
    try:
      with open(self.dbFile, 'r') as dbFile:
        for record in dbFile:
          records.add(record.rstrip())
    except OSError as e:
      if e.errno != errno.ENOENT:
        raise Exception(e)
    return records

  def run(self):
    db = self.load_DB()
    url = 'https://sfbay.craigslist.org/search/'
    if self.options.pic:
      hasPic = 'hasPic=1'
    else:
      hasPic = 'hasPic=0'
    if self.options.maxprice:
      maxPrice = 'max_price=' + self.options.maxprice
    else:
      maxPrice = ''
    if self.options.minprice:
      minPrice = 'min_price=' + self.options.minprice
    else:
      minPrice = ''
    queryWord = 'query=' + self.options.query.replace(' ', '%20')
    queryOpts = '&'.join(['format=rss', hasPic, maxPrice, minPrice, queryWord])
    parsed = feedparser.parse(url + self.options.group + '?' + queryOpts)
    new_items = 0
    with open(self.dbFile, 'a') as dbFile:
      sender = smtplib.SMTP(host='smtp.gmail.com', port=587)
      sender.starttls()
      sender.login(self.options.sender, self.options.password)
      for entry in parsed.entries:
        hash_hex = str(hashlib.sha1(entry['link'].encode('utf-8')).hexdigest())
        if hash_hex not in db:
          dbFile.write(hash_hex + '\n')
          msg = MIMEText('\n'.join([entry['title'].replace('&#x0024;', '$'), entry['link'], entry['summary']]))
          msg['From'] = 'me'
          msg['To'] = self.options.recepient
          msg['Subject'] = 'CL: ' + self.options.query
          sender.send_message(msg)
          new_items += 1
      sender.quit()
    now = datetime.datetime.now()
    if new_items:
      print(now, ': ', new_items, ' new posts processed for query:', queryOpts)
    else:
      print(now, ': no new posts for query:', queryOpts)

if __name__ == '__main__':
    checker = CheckCL()
    checker.run()
