import json
import struct

def parse_glb_bones(file_path):
    with open(file_path, 'rb') as f:
        magic = f.read(4)
        if magic != b'glTF': return
        version, length = struct.unpack('<II', f.read(8))
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        if chunk_type != 0x4E4F534A: return
        json_data = f.read(chunk_len).decode('utf-8')
        data = json.loads(json_data)
        if 'nodes' in data:
            print(f'Nodes in {file_path}:')
            for i, node in enumerate(data['nodes']):
                if 'name' in node:
                    print(f"  {i}: {node['name']}")

parse_glb_bones('models/character-human.glb')
