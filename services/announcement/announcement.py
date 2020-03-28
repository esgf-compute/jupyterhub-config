import argparse
import datetime
import json
import os

from tornado import escape
from tornado import gen
from tornado import ioloop
from tornado import web

from jupyterhub.services.auth import HubAuthenticated

class AnnouncementRequestHandler(HubAuthenticated, web.RequestHandler):
    hub_users = []
    allow_admin = True

    def initialize(self, storage):
        self.storage = storage

    @web.authenticated
    def post(self):
        user = self.get_current_user()
        doc = escape.json_decode(self.request.body)
        self.storage['announcement'] = doc['announcement']
        self.storage['level'] = doc.get('level', 'info').lower()
        if self.storage['level'] not in ('info', 'warning', 'danger'):
            self.set_status(400, 'Unsupported level')
        else:
            self.storage['timestamp'] = datetime.datetime.now().isoformat()
            self.storage['user'] = user['name']
            self.write_to_json(self.storage)

    def get(self):
        self.write_to_json(self.storage)

    @web.authenticated
    def delete(self):
        self.storage['announcement'] = ''
        self.write_to_json(self.storage)

    def write_to_json(self, doc):
        self.set_header('Content-Type', 'application/json; charset=UTF-8')
        self.write(escape.utf8(json.dumps(doc)))

def main():
    args = parse_arguments()
    application = create_application(**vars(args))
    application.listen(args.port)
    ioloop.IOLoop.current().start()

def parse_arguments():
    parser = argparse.ArgumentParser()
    api_prefix_default = os.environ.get('JUPYTERHUB_SERVICE_PREFIX', '/')
    parser.add_argument('--api-prefix', '-a', default=api_prefix_default, help='application API prefix')
    parser.add_argument('--port', '-p', default=8888, help='port for API to listen on', type=int)
    return parser.parse_args()

def create_application(api_prefix='/', handler=AnnouncementRequestHandler, **kwargs):
    storage = dict(announcement='', timestamp='', user='', level='')
    return web.Application([(f'{api_prefix}/?', handler, dict(storage=storage))])

if __name__ == '__main__':
    main()
