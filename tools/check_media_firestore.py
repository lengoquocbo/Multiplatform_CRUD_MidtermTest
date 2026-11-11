import argparse
import getpass
import json
import re
import sys
import uuid
from pathlib import Path
from firestore_data import request, commit, decode, ApiError, BASE

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--auth-stdin', action='store_true')
    args = parser.parse_args()
    if args.auth_stdin:
        credentials = json.loads(sys.stdin.readline())
    else:
        credentials = {'email': input('Email admin: '), 'password': getpass.getpass('Mật khẩu: ')}
    key = re.search("apiKey: '([^']+)'", Path('lib/firebase_options.dart').read_text()).group(1)
    def login():
        return request('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='+key, {**credentials, 'returnSecureToken': True})['idToken']
    token = login()
    payload = json.loads(Path('.tmp/media-check-payload.json').read_text(encoding='utf-8'))
    owned = []
    checks = []
    def allocate():
        identifier = 'media_excel_test_' + uuid.uuid4().hex
        owned.append(identifier)
        return identifier
    try:
        image_id = allocate()
        photo = {'name': 'Kiểm thử ảnh Data URI', 'price': 0, 'soluong': 1, 'image': payload['image']}
        commit({image_id: photo}, token)
        fresh_token = login()
        saved = decode(request(BASE+'/products/'+image_id, token=fresh_token)['fields'])
        assert saved == photo and set(saved) == {'name','price','soluong','image'}
        checks.append('Saved real compressed JPEG Data URI; fresh login/server GET returned exact image and exactly four fields')
        for invalid in ['data:image/jpeg;base64,YWJj', 'data:image/png;base64,/9j/AAAA', 'data:image/jpeg;base64,/9j/' + 'A'*204824, 'https://example.com/' + 'x'*2048]:
            invalid_id = allocate()
            try:
                commit({invalid_id: {**photo, 'image': invalid}}, token)
                raise AssertionError('Rules accepted invalid/oversized image')
            except ApiError as error:
                assert error.code == 403, str(error)
        checks.append('Rules rejected malformed image prefix/Base64, oversized Data URI and oversized HTTPS URL')
        for row in payload['excel']:
            identifier = allocate()
            commit({identifier: row}, token)
            saved = decode(request(BASE+'/products/'+identifier, token=token)['fields'])
            assert saved == row and len(saved) == 4
        checks.append(f"Imported {len(payload['excel'])} rows parsed by the app OOXML parser from the actual XLSX template; verified all rows with server GET")
        url = BASE+'/products/'+image_id
        try:
            request(url)
            raise AssertionError('Unauthenticated image read allowed')
        except ApiError as error:
            assert error.code in (401,403)
        checks.append('Unauthenticated image read denied')
    finally:
        for identifier in owned:
            request(BASE+'/products/'+identifier, token=token, method='DELETE')
            try:
                request(BASE+'/products/'+identifier, token=token)
                raise AssertionError('Test document remains')
            except ApiError as error:
                assert error.code == 404
    checks.append('Removed only owned test IDs; confirmed deletion by server GET 404')
    Path('docs/media-excel-live-check.json').write_text(json.dumps({'project':'crud-giuaki-quocbo','checks':checks,'scope':'Real Firebase API tests using app image processing and XLSX parser output; browser page reload and camera hardware were not tested.'},indent=2,ensure_ascii=False),encoding='utf-8')
    for check in checks: print(check)

if __name__ == '__main__':
    try: main()
    except (ApiError,ValueError,AssertionError,OSError) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)
