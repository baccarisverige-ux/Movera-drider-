#!/usr/bin/env python3
"""Conservative Dart import inventory; not proof that a retained seam is dead."""
import json,re
from pathlib import Path
from urllib.parse import unquote
root=Path(__file__).resolve().parents[1]
files={p.relative_to(root).as_posix():p for folder in ['lib','test'] for p in (root/folder).rglob('*.dart')}
graph={}
for name,p in files.items():
 refs=[]
 for uri in re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)['\"]",p.read_text()):
  uri=unquote(uri)
  if uri.startswith('package:movera/'): target='lib/'+uri[len('package:movera/'):]
  elif ':' in uri: continue
  else: target=(p.parent/uri).resolve().relative_to(root).as_posix()
  if target in files: refs.append(target)
 graph[name]=refs

def walk(roots):
 seen=set();stack=list(roots)
 while stack:
  node=stack.pop()
  if node in seen:continue
  seen.add(node);stack.extend(graph.get(node,[]))
 return seen
app=walk(['lib/main.dart']);tests=walk([name for name in files if name.startswith('test/')])
print(json.dumps({'app_reachable':len(app),'test_reachable':len(tests),'outside_app_graph':[name for name in sorted(files) if name.startswith('lib/') and name not in app],'outside_app_and_tests':[name for name in sorted(files) if name.startswith('lib/') and name not in app|tests]},indent=2))
