import argparse
import getpass
import json
import re
import sys
from pathlib import Path
from firestore_data import request, read_all, ApiError, BASE

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--auth-stdin',action='store_true')
    args=parser.parse_args()
    credentials=json.loads(sys.stdin.readline()) if args.auth_stdin else {'email':input('Email admin: '),'password':getpass.getpass('Mật khẩu: ')}
    key=re.search("apiKey: '([^']+)'",Path('lib/firebase_options.dart').read_text()).group(1)
    token=request('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='+key,{**credentials,'returnSecureToken':True})['idToken']
    data=read_all(token)
    expected={
      'Kiểm thử ảnh UI 82ac741f':(12345,2,None),
      'Kiểm thử Excel UI 82ac741f 1':(12500,3,'https://www.gstatic.com/webp/gallery/1.jpg'),
      'Kiểm thử Excel UI 82ac741f 2':(25000,5,'https://www.gstatic.com/webp/gallery/2.jpg'),
    }
    owned={}
    for name,(price,quantity,image) in expected.items():
        matches=[(identifier,p) for identifier,p in data.items() if p['name']==name]
        assert len(matches)==1, 'Cannot uniquely identify owned UI test document: '+name
        identifier,p=matches[0]
        assert p['price']==price and p['soluong']==quantity and len(p)==4
        assert p['image']==image if image else p['image'].startswith('data:image/jpeg;base64,')
        owned[identifier]=p
    unchanged={identifier:p for identifier,p in data.items() if identifier not in owned}
    for identifier in owned:
        request(BASE+'/products/'+identifier,token=token,method='DELETE')
        try:
            request(BASE+'/products/'+identifier,token=token)
            raise AssertionError('Owned UI test document remains')
        except ApiError as error: assert error.code==404
    remaining=read_all(token)
    assert all(remaining.get(identifier)==p for identifier,p in unchanged.items()), 'Pre-existing data changed during check'
    report={
      'project':'crud-giuaki-quocbo',
      'browser':'localhost:7358',
      'ui_observed':['Admin login succeeded with rebuilt Web plugins on fresh origin','HTML URL displayed image error','Actual file chooser selected JPEG bytes and switched active source to File','Product saved and Data URI image rendered after browser page reload','Actual XLSX file chooser previewed two valid rows','Confirmation imported 2/2 rows; save controls disabled after completion','Both imported products and HTTPS images rendered after browser page reload'],
      'server_verified':['Fresh server read confirmed exactly four fields in all three UI-created documents','File image field contains JPEG Data URI, not stale HTML URL','Both UI-imported Excel rows match values and image URLs','Deleted only three uniquely identified UI test IDs; GET confirmed 404; pre-existing documents unchanged'],
      'not_tested':['Real camera/webcam capture and permission denial on hardware','New Android runtime file/camera/Excel flow'],
      'screenshot':'docs/excel-import-ui.jpg'
    }
    Path('docs/media-excel-ui-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Verified real UI-created JPEG and two XLSX rows with fresh server GET. Removed exactly three owned test IDs; pre-existing documents unchanged.')

if __name__=='__main__':
    try:main()
    except (AssertionError,ApiError,ValueError,OSError) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)
