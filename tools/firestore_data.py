import argparse
import base64
import getpass
import json
import math
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

PROJECT = "crud-giuaki-quocbo"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
RESOURCE = f"projects/{PROJECT}/databases/(default)/documents/products/"

class ApiError(Exception):
    def __init__(self, code, body):
        self.code = code
        super().__init__(f"HTTP {code}: {body.get('error', {}).get('message', 'Firebase error')}")

def request(url, body=None, token=None, method=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    data = None if body is None else json.dumps(body, allow_nan=False).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, json.load(error)) from None

def validate(data):
    if not isinstance(data, dict) or not data or len(data) > 100:
        raise ValueError("JSON cần 1–100 sản phẩm với document ID làm khóa.")
    for key, p in data.items():
        if not isinstance(key, str) or not key or '/' in key or key in ('.', '..') or re.fullmatch(r'__.*__', key) or len(key.encode()) > 1500:
            raise ValueError("Document ID không hợp lệ.")
        if not isinstance(p, dict) or set(p) != {'name', 'price', 'soluong', 'image'}:
            raise ValueError(f"{key}: cần đúng bốn trường.")
        if not isinstance(p['name'], str) or not p['name'].strip() or p['name'] != p['name'].strip():
            raise ValueError(f"{key}: tên chưa trim hoặc rỗng.")
        if type(p['price']) not in (int, float) or not math.isfinite(p['price']) or p['price'] < 0:
            raise ValueError(f"{key}: giá không hợp lệ.")
        if type(p['soluong']) is not int or not 0 <= p['soluong'] <= 9007199254740991:
            raise ValueError(f"{key}: số lượng không hợp lệ.")
        if not isinstance(p['image'], str):
            raise ValueError(f"{key}: image phải là chuỗi.")
        image = p['image']
        if image.startswith('data:image/jpeg;base64,'):
            try:
                raw = base64.b64decode(image[23:], validate=True)
            except ValueError:
                raise ValueError(f"{key}: Base64 không hợp lệ.") from None
            if len(image) > 204823 or len(raw) > 153600 or not raw.startswith(b'\xff\xd8') or not raw.endswith(b'\xff\xd9'):
                raise ValueError(f"{key}: JPEG Data URI không hợp lệ hoặc vượt giới hạn.")
        else:
            uri = urllib.parse.urlsplit(image)
            if len(image) > 2048 or uri.scheme != 'https' or not uri.hostname or uri.username or re.search(r'\s', image):
                raise ValueError(f"{key}: URL cần HTTPS hợp lệ, tối đa 2048 ký tự.")
    return data

def encode(p):
    return {k: ({'integerValue': str(v)} if type(v) is int else {'doubleValue': v} if type(v) is float else {'stringValue': v}) for k, v in p.items()}

def decode(fields):
    result = {}
    for key, value in fields.items():
        if 'integerValue' in value: result[key] = int(value['integerValue'])
        elif 'doubleValue' in value: result[key] = float(value['doubleValue'])
        elif 'stringValue' in value: result[key] = value['stringValue']
        else: raise ValueError(f"Trường {key} có kiểu không hợp lệ.")
    return result

def read_all(token):
    result, page = {}, ''
    while True:
        url = BASE + '/products?pageSize=1000' + ('&pageToken=' + urllib.parse.quote(page, safe='') if page else '')
        response = request(url, token=token)
        for doc in response.get('documents', []):
            result[doc['name'].split('/')[-1]] = decode(doc.get('fields', {}))
        page = response.get('nextPageToken')
        if not page: break
    if result:
        for key, value in result.items(): validate({key: value})
    return result

def commit(data, token, create=True):
    writes = [{'update': {'name': RESOURCE + key, 'fields': encode(value)}, 'currentDocument': {'exists': not create}} for key, value in data.items()]
    return request(BASE + ':commit', {'writes': writes}, token)

def save_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as output:
        json.dump(data, output, ensure_ascii=False, indent=2, allow_nan=False)
        output.write('\n')

def live_check(token, key):
    checks, created, other_token = [], [], None
    sample = {'name': 'Sản phẩm kiểm thử Firebase', 'price': 12500.5, 'soluong': 3, 'image': 'https://www.gstatic.com/webp/gallery/1.jpg'}
    test_id = 'codex_test_' + uuid.uuid4().hex
    try:
        try:
            request(BASE + '/products')
            raise AssertionError('Chưa đăng nhập vẫn đọc được dữ liệu.')
        except ApiError as e:
            assert e.code in (401, 403)
            checks.append('Unauthenticated read denied')
        commit({test_id: sample}, token); created.append(test_id)
        actual = decode(request(BASE + '/products/' + test_id, token=token)['fields'])
        assert actual == sample
        checks.append('Create then fresh server GET equals exactly four fields')
        for field, value in [('name', ''), ('name', '   '), ('price', -1), ('price', 'abc'), ('soluong', -1), ('soluong', 1.5), ('image', 'http://example.com/a.png')]:
            bad = dict(sample); bad[field] = value
            try:
                commit({test_id: bad}, token, create=False)
                raise AssertionError('Rules accepted invalid ' + field)
            except ApiError as e:
                assert e.code == 403, str(e)
        bad = dict(sample); bad['description'] = 'extra'
        try:
            commit({test_id: bad}, token, create=False)
            raise AssertionError('Rules accepted extra field')
        except ApiError as e: assert e.code == 403
        for special in ['NaN', 'Infinity', '-Infinity']:
            fields=encode(sample); fields['price']={'doubleValue':special}
            try:
                request(BASE + ':commit', {'writes':[{'update':{'name':RESOURCE+test_id,'fields':fields},'currentDocument':{'exists':True}}]}, token)
                raise AssertionError('Rules accepted ' + special)
            except ApiError as e: assert e.code == 403, str(e)
        checks.append('Rules reject invalid types, negative values, blank name, HTTP URL, extra field, NaN and infinity')
        changed = dict(sample); changed['name'] += ' đã sửa'; changed['soluong'] = 5
        commit({test_id: changed}, token, create=False)
        assert decode(request(BASE + '/products/' + test_id, token=token)['fields']) == changed
        checks.append('Update verified by fresh server GET')
        data = read_all(token)
        save_json(Path('data/products.json'), data)
        checks.append('Exported server products into data/products.json')
        imported_id = 'codex_import_' + uuid.uuid4().hex
        imported = validate({imported_id: data[test_id]})
        commit(imported, token); created.append(imported_id)
        assert decode(request(BASE + '/products/' + imported_id, token=token)['fields']) == changed
        try:
            commit(imported, token)
            raise AssertionError('Import overwrote existing ID')
        except ApiError as e: assert e.code in (400, 409, 412)
        checks.append('JSON reimport verified, existing ID conflict rejected')
        signup = request('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + key, {'email': 'crud-test-' + uuid.uuid4().hex + '@example.com', 'password': uuid.uuid4().hex, 'returnSecureToken': True})
        other_token = signup['idToken']
        for url, body in [(BASE + '/products', None), (BASE + ':commit', {'writes': [{'update': {'name': RESOURCE + test_id, 'fields': encode(sample)}}]})]:
            try:
                request(url, body, other_token)
                raise AssertionError('Non-admin was allowed')
            except ApiError as e: assert e.code == 403
        checks.append('Real non-admin account read/write denied')
    finally:
        for item in created:
            request(BASE + '/' + 'products/' + item, token=token, method='DELETE')
            try:
                request(BASE + '/products/' + item, token=token)
                raise AssertionError('Test document was not deleted')
            except ApiError as e: assert e.code == 404
        if other_token:
            request('https://identitytoolkit.googleapis.com/v1/accounts:delete?key=' + key, {'idToken': other_token})
    checks.append('Only generated test documents/account deleted; deletions verified by GET 404')
    Path('docs').mkdir(exist_ok=True)
    Path('docs/live-check.json').write_text(json.dumps({'project': PROJECT, 'checks': checks, 'export_note': 'Export contains a temporary test product actually read from Firestore. Test documents were removed afterward.'}, ensure_ascii=False, indent=2), encoding='utf-8')
    for check in checks: print(check)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['export', 'import', 'check'])
    parser.add_argument('file', nargs='?', default='data/products.json')
    parser.add_argument('--auth-stdin', action='store_true')
    args = parser.parse_args()
    if args.auth_stdin:
        credentials = json.loads(sys.stdin.readline())
        email, password = credentials['email'], credentials['password']
    else:
        email, password = input('Email admin: '), getpass.getpass('Mật khẩu: ')
    key = re.search("apiKey: '([^']+)'", Path('lib/firebase_options.dart').read_text()).group(1)
    auth = request('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + key, {'email': email, 'password': password, 'returnSecureToken': True})
    token = auth['idToken']
    if args.action == 'export':
        data = read_all(token); save_json(Path(args.file), data); print(f'Đã xuất {len(data)} sản phẩm từ máy chủ.')
    elif args.action == 'import':
        data = validate(json.loads(Path(args.file).read_text(encoding='utf-8-sig')))
        commit(data, token); print(f'Đã nhập {len(data)} sản phẩm. Không ghi đè ID đã có.')
    else:
        live_check(token, key)

if __name__ == '__main__':
    try: main()
    except (ApiError, ValueError, AssertionError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
